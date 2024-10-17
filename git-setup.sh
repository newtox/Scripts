#!/bin/bash

handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Prompt for GitHub username if not set
USERNAME=${GITHUB_USERNAME:-$(read -p "Enter GitHub username: " uname; echo $uname)}

# GitHub API Token
GITHUB_TOKEN=""

echo "Do you want to set your Git username and email globally? (y/n)"
read -r set_global_config

if [ "$set_global_config" = "y" ]; then
    read -p "Enter your name for Git commits: " git_name
    read -p "Enter your email for Git commits: " git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    echo "Global Git configuration set."
elif [ "$set_global_config" != "n" ]; then
    echo "Invalid choice. Proceeding without setting global config."
fi

# Prompt for repository visibility
echo "Should the repository be public or private?"
select vis in "Public" "Private"; do
    case $vis in
        Public ) REPO_VISIBILITY="false"; break;;
        Private ) REPO_VISIBILITY="true"; break;;
    esac
done

echo "You've chosen $vis visibility for your repository."

# Directory to initialize git repo
read -p "Enter the folder to initialize git repo (or press Enter for current directory): " folder
folder=${folder:-"."}

# Check if the folder exists
[ ! -d "$folder" ] && handle_error "Directory $folder does not exist."

cd "$folder" || handle_error "Failed to change directory to $folder"

# Initialize Git if not already initialized
[ ! -d .git ] && git init || echo "Git repository already initialized."

# Prompt for repository name
read -p "Enter repository name (or press Enter to use folder name): " repo_name
repo_name=${repo_name:-$(basename "$folder")}

create_repo() {
    echo "Creating repository $repo_name on GitHub..."
    local curl_response=$(curl -X POST \
      https://api.github.com/user/repos \
      -H "Authorization: token $GITHUB_TOKEN" \
      -d "{\"name\":\"$repo_name\",\"private\":$REPO_VISIBILITY}")
    
    if [[ $? -ne 0 ]]; then
        handle_error "Failed to create repository. Network or authorization issue."
    fi
    
    if echo "$curl_response" | grep -q '"id":\|"name":"'${repo_name}'"'; then
        echo "Repository $repo_name successfully created at $(echo "$curl_response" | grep -o '"html_url":"[^"]*' | cut -d'"' -f4)"
    else
        error_message=$(echo "$curl_response" | grep -o '"message":"[^"]*' | cut -d'"' -f4)
        if [ -z "$error_message" ]; then
            error_message="Unknown error occurred. Response: $curl_response"
        fi
        handle_error "Failed to create repository: $error_message"
    fi
}

create_repo

# Wait for a second to ensure repo creation propagation
sleep 1

# Set HTTPS URL for repository
REPO_URL="https://github.com/$USERNAME/$repo_name.git"

#!/bin/bash

# Select primary file type for .gitignore
echo "Select primary file type for .gitignore (enter the number):"
select lang in "None" "Python" "JavaScript" "Java" "C++" "Ruby" "Go" "Laravel" "Django" "React" "Angular" "Flask" "Express" "Other"; do
    case $lang in
        None)
            echo "# Basic .gitignore" > .gitignore
            echo "*" >> .gitignore
            echo "!*.md" >> .gitignore
            echo "!.gitignore" >> .gitignore
            echo "!src/" >> .gitignore
            echo "Created a basic .gitignore file."
            break
            ;;
        Python)
            echo "# .gitignore for Python" > .gitignore
            echo "__pycache__/" >> .gitignore
            echo "*.py[cod]" >> .gitignore
            echo "*.pyo" >> .gitignore
            echo "*.pyd" >> .gitignore
            echo "*.db" >> .gitignore
            echo "*.egg-info/" >> .gitignore
            echo "dist/" >> .gitignore
            echo "build/" >> .gitignore
            echo ".env" >> .gitignore
            echo "Created a Python-specific .gitignore."
            break
            ;;
        JavaScript)
            echo "# .gitignore for JavaScript" > .gitignore
            echo "node_modules/" >> .gitignore
            echo "npm-debug.log" >> .gitignore
            echo "yarn-error.log" >> .gitignore
            echo "dist/" >> .gitignore
            echo "build/" >> .gitignore
            echo ".DS_Store" >> .gitignore
            echo ".env" >> .gitignore
            echo "Created a JavaScript-specific .gitignore."
            break
            ;;
        Java)
            echo "# .gitignore for Java" > .gitignore
            echo "*.class" >> .gitignore
            echo "*.jar" >> .gitignore
            echo "*.war" >> .gitignore
            echo "*.ear" >> .gitignore
            echo "*.log" >> .gitignore
            echo "*.swp" >> .gitignore
            echo "*.swo" >> .gitignore
            echo "target/" >> .gitignore
            echo "bin/" >> .gitignore
            echo "build/" >> .gitignore
            echo ".idea/" >> .gitignore
            echo "*.iml" >> .gitignore
            echo "*.hprof" >> .gitignore
            echo "Created a Java-specific .gitignore."
            break
            ;;
        C++)
            echo "# .gitignore for C++" > .gitignore
            echo "*.o" >> .gitignore
            echo "*.obj" >> .gitignore
            echo "*.exe" >> .gitignore
            echo "*.out" >> .gitignore
            echo "*.class" >> .gitignore
            echo "*.so" >> .gitignore
            echo "*.dSYM/" >> .gitignore
            echo "*.swp" >> .gitignore
            echo "*.swo" >> .gitignore
            echo "*.log" >> .gitignore
            echo "*.vscode/" >> .gitignore
            echo "Created a C++-specific .gitignore."
            break
            ;;
        Ruby)
            echo "# .gitignore for Ruby" > .gitignore
            echo "*.gem" >> .gitignore
            echo "*.rbc" >> .gitignore
            echo "/.bundle" >> .gitignore
            echo "/vendor/" >> .gitignore
            echo "log/*" >> .gitignore
            echo "tmp/*" >> .gitignore
            echo "coverage/" >> .gitignore
            echo "*.log" >> .gitignore
            echo "*.swp" >> .gitignore
            echo "Created a Ruby-specific .gitignore."
            break
            ;;
        Go)
            echo "# .gitignore for Go" > .gitignore
            echo "*.exe" >> .gitignore
            echo "*.test" >> .gitignore
            echo "*.out" >> .gitignore
            echo "bin/" >> .gitignore
            echo "vendor/" >> .gitignore
            echo "*.swp" >> .gitignore
            echo "Created a Go-specific .gitignore."
            break
            ;;
        Laravel)
            echo "# .gitignore for Laravel" > .gitignore
            echo "/public/storage" >> .gitignore
            echo "/storage/*.key" >> .gitignore
            echo "/vendor" >> .gitignore
            echo "/node_modules" >> .gitignore
            echo "/.vscode" >> .gitignore
            echo "/.env" >> .gitignore
            echo "Homestead.yaml" >> .gitignore
            echo "Homestead.json" >> .gitignore
            echo "npm-debug.log" >> .gitignore
            echo "yarn-error.log" >> .gitignore
            echo "package-lock.json" >> .gitignore
            echo "yarn.lock" >> .gitignore
            echo "# IDE and OS files" >> .gitignore
            echo ".DS_Store" >> .gitignore
            echo "Thumbs.db" >> .gitignore
            echo ".idea" >> .gitignore
            echo "*.sublime-project" >> .gitignore
            echo "*.sublime-workspace" >> .gitignore
            echo ".vagrant" >> .gitignore
            echo "/.phpunit.result.cache" >> .gitignore
            echo "/.phpunit.result.cache.json" >> .gitignore
            echo "# Logs" >> .gitignore
            echo "*.log" >> .gitignore
            echo "/storage/logs/*" >> .gitignore
            echo "/storage/framework/sessions/*" >> .gitignore
            echo "/storage/framework/views/*" >> .gitignore
            echo "/storage/app/public/*" >> .gitignore
            echo "/storage/debugbar/*" >> .gitignore
            echo "# Temporary files" >> .gitignore
            echo "*.tmp" >> .gitignore
            echo "*.temp" >> .gitignore
            echo "*.bak" >> .gitignore
            echo "*.swp" >> .gitignore
            echo "*.swo" >> .gitignore
            echo "Created a Laravel-specific .gitignore."
            break
            ;;
        Django)
            echo "# .gitignore for Django" > .gitignore
            echo "*.pyc" >> .gitignore
            echo "*.pyo" >> .gitignore
            echo "__pycache__/" >> .gitignore
            echo "db.sqlite3" >> .gitignore
            echo "media/" >> .gitignore
            echo "staticfiles/" >> .gitignore
            echo ".env" >> .gitignore
            echo "*.log" >> .gitignore
            echo "*.pot" >> .gitignore
            echo "*.py[cod]" >> .gitignore
            echo "Created a Django-specific .gitignore."
            break
            ;;
        React)
            echo "# .gitignore for React" > .gitignore
            echo "node_modules/" >> .gitignore
            echo "build/" >> .gitignore
            echo ".DS_Store" >> .gitignore
            echo "npm-debug.log" >> .gitignore
            echo "yarn-error.log" >> .gitignore
            echo ".env" >> .gitignore
            echo "Created a React-specific .gitignore."
            break
            ;;
        Angular)
            echo "# .gitignore for Angular" > .gitignore
            echo "node_modules/" >> .gitignore
            echo "dist/" >> .gitignore
            echo ".tmp/" >> .gitignore
            echo "*.log" >> .gitignore
            echo ".DS_Store" >> .gitignore
            echo "npm-debug.log" >> .gitignore
            echo "yarn-error.log" >> .gitignore
            echo ".env" >> .gitignore
            echo "Created an Angular-specific .gitignore."
            break
            ;;
        Flask)
            echo "# .gitignore for Flask" > .gitignore
            echo "__pycache__/" >> .gitignore
            echo "*.pyc" >> .gitignore
            echo "*.pyo" >> .gitignore
            echo "*.db" >> .gitignore
            echo "*.env" >> .gitignore
            echo "instance/" >> .gitignore
            echo "*.log" >> .gitignore
            echo "Created a Flask-specific .gitignore."
            break
            ;;
        Express)
            echo "# .gitignore for Express" > .gitignore
            echo "node_modules/" >> .gitignore
            echo "npm-debug.log" >> .gitignore
            echo ".env" >> .gitignore
            echo ".DS_Store" >> .gitignore
            echo "logs/" >> .gitignore
            echo "Created an Express-specific .gitignore."
            break
            ;;
        Other)
            read -p "Enter specific language or environment: " custom_lang
            echo "# Custom .gitignore for $custom_lang" > .gitignore
            echo "Fallback: basic ignore for custom type." >> .gitignore
            echo "Created a custom .gitignore for $custom_lang."
            break
            ;;
        *)
            echo "Invalid selection. Please try again."
            ;;
    esac
done

# Check and correct or add remote
if git remote | grep -q 'origin'; then
    echo "Remote 'origin' already exists. Checking its URL..."
    existing_url=$(git remote get-url origin)
    if [[ $existing_url == git@github.com:* ]]; then
        echo "Updating SSH URL to HTTPS for origin..."
        git remote set-url origin $REPO_URL
    else
        echo "Remote URL is already HTTPS or does not match expected SSH format. Removing and re-adding..."
        git remote remove origin
    fi
fi

# Now safely add the remote if it was removed or didn't exist
git remote add origin $REPO_URL || echo "Remote 'origin' might already exist with correct URL, proceeding..."

# Stage all changes
git add . || handle_error "Failed to stage changes."

# Check if there are any changes to commit, if not, create README.md
if [ $(git status --porcelain | wc -l) -eq 0 ]; then
    echo "No changes detected. Creating initial README.md"
    echo "# $repo_name" > README.md
    git add README.md || handle_error "Failed to stage README.md"
fi

# Commit the changes
git commit -m "Initial commit with ${lang:-basic} .gitignore" || handle_error "Failed to commit."

# Ensure main branch exists
if ! git show-ref --verify --quiet refs/heads/main; then
    git checkout -b main > /dev/null 2>&1 || handle_error "Failed to create main branch."
fi

# Push to the main branch using HTTPS
git push --set-upstream origin main || handle_error "Failed to push to origin/main."

# Optionally, to handle line endings on Windows
git config --global core.autocrlf input