# Validates if the variable name was specified
function validate_name(){
  # Check if the function was called with at least one parameter
  if [ -z "$1" ]; then
    echo "Variable name not specified..."
    exit 1
  fi

  # Validate the variable name using a regex pattern
  if ! [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Invalid variable name specified"
    exit 1
  fi

  echo "$1"
}

# Validates if the variable name and the value was specified
function validate_name_value(){
  name=$(validate_name $*);

  if [ -z "$2" ]; then
    echo "Variable value not specified..."
    # exit 1
  fi
  value="$2"
  echo "${name}:${value}"
}

function validate_exists(){
  if cat ~/.config/zsh/variables.sh | grep -q "export $1="; then
    return 0
  fi
  return 1
}

# Creates perm variable
function createvar(){
  name=$(validate_name $*)
  
  if validate_exists; then
    echo "The variable name already exists"
  fi

  echo "export $name=''" >> ~/.config/zsh/variables.sh
  source ~/.config/zsh/variables.sh;  
}

# Deletes perm variable
function delvar(){
  name=$(validate_name $*)
  
  if ! validate_exists $*; then
    echo "The variable doesn't exists"
  fi

  sed -i --follow-symlinks "/^export $name=/d" ~/.config/zsh/variables.sh
  source ~/.config/zsh/variables.sh;  
}

# Updates variable value
function upvar(){
  IFS=":" read -r name value <<< "$(validate_name_value $*)"

  if ! validate_exists $*; then
    echo "The variable doesn't exists"
  fi
  
	sed -i --follow-symlinks "s+^export $name='.*+export $name='$value'+g" ~/.config/zsh/variables.sh;
  source ~/.config/zsh/variables.sh;
}
