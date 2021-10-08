# install homebrew
if ! command -v brew > /dev/null 2>&1; then
  # Install homebrew in Intel Mac or M1 Mac on Rosetta2
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

