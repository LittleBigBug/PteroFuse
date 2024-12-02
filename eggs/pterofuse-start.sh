#!/bin/bash

LAYERS_DIR="/mnt/server-layers"
BASE_SERVER_DIR="${LAYERS_DIR}/_server-bases/${BASE_NAME}"
SERVER_INST_LAYER="${LAYERS_DIR}/_server-instances/${SERVER_ID}"

mkdir -p "${SERVER_INST_LAYER}" || echo "Failed to create the server instance directory! Aborting..." && exit 1

## EXAMPLE DATA
## LAYERS_CONFIG="git:https://github.com/mump-surf/surf-base#branch; git:https://github.com/mump-surf/skill-surf-base#/commit; git:https://github.com/mump-surf/surf-t1-maps"
## EXAMPLE DATA

GENERATED_UNIONFS=""

# Empty layer config will mean only the base game install layer + unique server instance layer
if [ -n "${LAYERS_CONFIG}" ]; then
  # Split layer config and reverse its order (inputted into unionfs backwards)
  LAYERS=$(echo "$LAYERS_CONFIG" | tr -d "[:space:]" | tr ";" "\n" | tac)

  for LAYER_CFG in $LAYERS; do
    LAYER_TYPE=$(echo "$LAYER_CFG" | cut -d ":" -f 1)
    LAYER_VALUE=$(echo "$LAYER_CFG" | cut -d ":" -f 2)

    case $LAYER_TYPE in
      # Only git repos are supported for now
      "git")
        GIT_URL=$(echo "$LAYER_VALUE" | cut -d "#" -f 1)
        GIT_BRANCH_COMMIT=$(echo "$LAYER_VALUE" | cut -d "#" -f 2)

        GIT_ACCOUNT=$(echo "$GIT_URL" | cut -d "/" -f 4)
        GIT_REPO=$(echo "$GIT_URL" | cut -d "/" -f 5)

        LAYER_DIR="${LAYERS_DIR}/_git/${GIT_ACCOUNT}/${GIT_REPO}"

        if [ "$GIT_BRANCH_COMMIT" == "$GIT_URL" ]; then
          # If theres no branch or commit specified
          GIT_BRANCH=""
          LAYER_DIR+="/__default-latest"
        else
          # branch and/or commit was specified
          GIT_BRANCH=$(echo "$GIT_BRANCH_COMMIT" | cut -d "/" -f 1)
          GIT_COMMIT=$(echo "$GIT_BRANCH_COMMIT" | cut -d "/" -f 2)

          if [ -n "$GIT_BRANCH" ]; then
            # If a branch was specified
            LAYER_DIR+="/${GIT_BRANCH}"
          else
            LAYER_DIR+="/__default"
          fi

          if [ "$GIT_COMMIT" == "$GIT_BRANCH" ]; then
            # If no commit specified
            GIT_COMMIT=""
            LAYER_DIR+="-latest"
          else
            LAYER_DIR+="-${GIT_COMMIT}"
          fi
        fi

        mkdir -p "${LAYER_DIR}"

        if [ -z "$( ls -A "${LAYER_DIR}" )" ]; then
          # Clone the github repo at the specified branch, and only that branch, with only one revision
          # shellcheck disable=SC2046
          git clone --single-branch --depth 1 \
            $( [[ -z ${GIT_BRANCH} ]] || printf %s "--branch ${GIT_BRANCH}" ) \
            "${GIT_URL}" "${LAYER_DIR}"

          if [ -n "${GIT_COMMIT}" ]; then
            # If specified, fetch & checkout the specific commit hash provided
            cd "${LAYER_DIR}" || echo "Failed to CD into new cloned layer dir?!" && continue
            git fetch --depth=1 origin "${GIT_COMMIT}"
            git checkout "${GIT_COMMIT}"
          fi
        else
          if [ -n "${GIT_COMMIT}" ]; then
            # If specified, fetch & checkout the specific commit hash provided
            cd "${LAYER_DIR}" || echo "Failed to CD into new cloned layer dir?!" && continue
            git fetch --depth=1 origin "${GIT_COMMIT}"
            git checkout "${GIT_COMMIT}"
          else
            git checkout "${GIT_BRANCH}"
            git pull
          fi
        fi

        GENERATED_UNIONFS+="${LAYER_DIR}=RO:"
        ;;
    esac
  done
fi

# if ONLY_UPDATE is specified, don't run the fuse. The server is likely running.
if [ -z "${ONLY_UPDATE}" ]; then
#  Does this break everything (ie, pterodactyl /home/container mount?) todo;
#  umount /home/container

  # UnionFS union order
  # Example:
  # /mnt/server-layers/_server-instances/098sda098sd098=RW:/mnt/server-layers/_git/mump-surf/surf-base/commitid-or-branch=RO:/mnt/server-layers/_server-bases/source-232330=RO
  UNIONFS_UNION="${SERVER_INST_LAYER}=RW:${GENERATED_UNIONFS}${BASE_SERVER_DIR}=RO"

  # Fuse!
  unionfs-fuse -o cow "${UNIONFS_UNION}" /home/container
fi