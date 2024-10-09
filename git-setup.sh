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

# Select .gitignore type
echo "Select primary file type for .gitignore:"
select lang in "None" "Python" "JavaScript" "Java" "C++" "Ruby" "Go" "Other"; do
    case $lang in
        None)
            echo "# Basic .gitignore" > .gitignore
            echo "*" >> .gitignore
            echo "!*.md" >> .gitignore
            echo "!.gitignore" >> .gitignore
            echo "!src/" >> .gitignore
            echo "Created basic .gitignore file."
            break
            ;;
        Other)
            read -p "Enter specific language or environment: " custom_lang
            lang=$custom_lang
            echo "# Custom .gitignore for $custom_lang" > .gitignore
            echo "Fallback: basic ignore for custom type."
            break
            ;;
        *) 
            echo "# .gitignore for $lang" > .gitignore
            # Here you would typically fetch or create language-specific .gitignore content
            echo "Created $lang specific .gitignore."
            break
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