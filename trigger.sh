#!/bin/bash -e
######## usage #############
# requires an API_TOKEN and pipelines_api_url envs to be predefined
# for interacting with pipelines API
#
# requires jq
#
# Usage:
# slack.sh [pipelineName] [branchName] [optional step=[stepName] projectKey=[projectKey]]
# pipeline and branch are required
# step is optional if default is set
# project is optional but could have ambiguous results if not used
# when using multiple projects
############################

if [ -z "$pipelines_api_url" ]; then
  echo "Required variable pipelines_api_url not defined" >&2
  exit 1
fi
if [ -z "$API_TOKEN" ]; then
  echo "Required variable API_TOKEN not defined" >&2
  exit 1
fi

function process_command() {
  # first argument is pipeline
  # second argument is branch
  # remaining arguments can be projectKey=xyz and/or step=abc
  # if no step provided, default step is used
  if [[ $# -lt 2 ]]; then
    echo "Usage: ./trigger.sh [pipeline] [branch] ...[step=<step> projectKey=<key>]" >&2
    exit 1
  fi
  pipeline="$1"
  shift
  branch="$1"
  shift

  while [[ $# -gt 0 ]]; do
    LEFT="${1%=*}"
    RIGHT="${1#*=}"
    case $LEFT in
      step)
        step=$RIGHT
        shift
        ;;
      project)
        project=$RIGHT
        shift
        ;;
      injectedEnvs)
        injectedEnvs=$RIGHT
        shift
        ;;
      *)
        echo "Warning: unrecognized argument: \"$LEFT\"" >&2
        shift
        ;;
    esac
  done

  if [ -z "$pipeline" ]; then
    echo "Invalid arguments. 'pipeline' is required." >&2
    exit 1
  fi

  if [ -z "$step" ]; then
    if [ -z "$DEFAULT_STEP" ]; then
      echo "Invalid arguments. No 'step' or 'DEFAULT_STEP' provided" >&2
      exit 1
    else
      echo "No step provided. using default step $DEFAULT_STEP" >&2
      step="$DEFAULT_STEP"
    fi
  fi

}

function get_project_id() {
  echo "getting project id for project key: $project" >&2
  rm project.json || true
  curl -XGET \
    -H "Authorization:Bearer $API_TOKEN" \
    "$pipelines_api_url/projects?sourceIds=$project" \
     -o project.json

  if [ ! -f "project.json" ]; then
    echo "something went wrong. no project.json from api" >&2
    exit 1
  else
   project_id=$(cat project.json | jq '.[0].id')
   if [ -z "$project_id" ] || [ "$project_id" == "null" ]; then
     echo "unable to get project id. response:" >&2
     cat project.json >&2
     exit 1
   else
     echo "found project id: $project_id" >&2
   fi
  fi
  echo $project_id
}

function get_pipeline_id {
  echo "getting pipeline id for name: $pipeline and branch $branch" >&2
  rm pipeline.json || true
  if [ -z "$projectId" ]; then
    curl -XGET -G \
      -H "Authorization:Bearer $API_TOKEN" \
      --data-urlencode "pipelineSourceBranches=$branch" \
      --data-urlencode "names=$pipeline" \
      "$pipelines_api_url/pipelines" \
      -o pipeline.json
  else
    curl -XGET -G \
      -H "Authorization:Bearer $API_TOKEN" \
      --data-urlencode "pipelineSourceBranches=$branch" \
      --data-urlencode "names=$pipeline" \
      --data-urlencode "projectIds=$projectId" \
      "$pipelines_api_url/pipelines" \
      -o pipeline.json
  fi

  if [ ! -f "pipeline.json" ]; then
    echo "something went wrong. no pipeline.json from api" >&2
    exit 1
  else
   pipeline_id=$(cat pipeline.json | jq '.[0].id')
   if [ -z "$pipeline_id" ] || [ "$pipeline_id" == "null" ]; then
     echo "unable to get pipeline id. response:" >&2
     cat pipeline.json >&2
     exit 1
   else
     echo "found pipeline id: $pipeline_id" >&2
   fi
  fi
  echo $pipeline_id
}

function get_pipelineStep_id {
  echo "getting pipelineStep id for name: $step and pipelineId $pipelineId" >&2
  rm pipelineStep.json || true
  curl -XGET -G \
    -H "Authorization:Bearer $API_TOKEN" \
    --data-urlencode "pipelineIds=$pipelineId" \
    --data-urlencode "names=$step" \
    "$pipelines_api_url/pipelineSteps" \
     -o pipelineStep.json

  if [ ! -f "pipelineStep.json" ]; then
    echo "something went wrong. no pipelineStep.json from api" >&2
    exit 1
  else
   step_id=$(cat pipelineStep.json | jq '.[0].id')
   if [ -z "$step_id" ] || [ "$step_id" == "null" ]; then
     echo "unable to get pipelineStep id. response:" >&2
     cat pipelineStep.json >&2
     exit 1
   else
     echo "found pipelineStep id: $step_id" >&2
   fi
  fi
  echo $step_id
}

function trigger_step() {
  echo "triggering pipelineStep for id $stepId" >&2

  curl -XPOST \
    -H "Authorization:Bearer $API_TOKEN" \
    -H "Content-Type:application/json" \
    "$pipelines_api_url/pipelineSteps/${stepId}/trigger" \
    -d'{}' \
    -o triggerOut.json

  if [ ! -f "triggerOut.json" ]; then
    echo "something went wrong. no triggerOut.json from api" >&2
    exit 1
  else
    cat triggerOut.json >&2
  fi
}

# The following variables are set
# by processing the inputs to this script
#
export pipeline=""
export step=""
export defaultStep=""
export branch=""
export project=""
export injectedEnvs="" # future use
export projectId=""
export pipelineId=""
export stepId=""


process_command "$@"
if [ -n "$project" ]; then
  projectId=$(get_project_id)
  echo "got projectId $projectId"
fi
pipelineId=$(get_pipeline_id)
echo "got pipelineId $pipelineId"

stepId=$(get_pipelineStep_id)
echo "got pipelineStepId $stepId"

if [ -z "$stepId" ]; then
  echo "Unable to find corresponding pipelineStep ID for supplied arguments." >&2
  exit 1
fi
trigger_step