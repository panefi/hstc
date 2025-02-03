#!/usr/bin/env bash
set -euo pipefail

# 1) Clean and recreate the build folders
rm -rf build
mkdir -p build/lambdas
mkdir -p build/layers

################################################################################
# ZIP ALL LAMBDAS
################################################################################
echo "Zipping all Lambdas..."
# For each subfolder of "lambdas/", create a zip in "build/lambdas/"
for lambda_dir in lambdas/*/; do
  # Skip if it's not actually a directory
  if [ ! -d "$lambda_dir" ]; then
    continue
  fi

  # Extract folder name (e.g. "get_gates")
  lambda_name=$(basename "$lambda_dir")

  zip_file="build/lambdas/${lambda_name}.zip"
  echo "  -> Creating zip for Lambda '$lambda_name' at '$zip_file'"

  # Remove old zip if any
  rm -f "$zip_file"

  # Zip everything in that Lambda directory (including lambda_handler.py)
  (
    cd "$lambda_dir"
    zip -r "../../${zip_file}" . 
  )
done

################################################################################
# ZIP LAYERS
################################################################################
echo ""
echo "Zipping Python layers so that they start with 'python/' at the root..."

# For each subfolder in 'layers/', create a zip in 'build/layers/'
for layer_dir in layers/*/; do
  # Skip if it's not actually a directory
  if [ ! -d "$layer_dir" ]; then
    continue
  fi

  # If there's no 'python' subfolder, skip
  if [ ! -d "${layer_dir}python" ]; then
    echo "  -> Skipping '$layer_dir': No 'python' folder found."
    continue
  fi

  # E.g. "common_code", "third_party", etc.
  layer_name=$(basename "$layer_dir")
  zip_path="build/layers/${layer_name}.zip"

  echo "  -> Creating '$zip_path' from '${layer_dir}python/'"

  # Remove any existing zip
  rm -f "$zip_path"

  # Go inside the layer folder and zip ONLY the `python/` directory
  # so that unzip yields:
  #  python/
  #    ...
  (
    cd "$layer_dir"
    zip -r "../../${zip_path}" "python"  
  )
done

