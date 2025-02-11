## Create pull requests

1. Install git and choose the checkout and commit as LF option otherwise the scripts in the [additions](./additions/) folder will not execute.
2. Set your global username and email
   - `git config --global user.email "yourusername@yourorganization.no"`
   - `git config --global user.name "yourusername"`
3. Navigate to the [devcontainer-toolbox](https://github.com/norwegianredcross/devcontainer-toolbox) repo and create a new fork.
4. Clone the fork
   - `git clone https://github.com/yourusername/devcontainer-toolbox`
5. Use git remote -v to see your local and remote git repositories in your current project folder. In order for you to create a pull request you must add the remote repo to your project git folder. This will allow you to pull the latest changes into your current local branch.
   - `git remote add upstream https://github.com/norwegianredcross/devcontainer-toolbox`
6. If you want to commit and push you have to do it to your forked repo, then create a pullrequest with your local changes.
7. First ensure that your local main branch is up to date with the remote main branch.
   - Ensure a clean working directory
     - `git stash`
   - `git checkout main`
   - This will pull changes from remote so you can compare changes to your local forked repo
     - `git pull upstream main`
8. Make a new feature branch
   - `git checkout -b some_feat_branch`
9.  Make some changes, then stage and commit
    - `git add .`
    - `git commit -m "some changes"`
10. Publish the branch to your forked repo. -u will publish your new branch to your private repo. If it's already published just use git push.
    - `git push -u origin some_feat_branch`
11. Navigate to the remote repo [devcontainer-toolbox](https://github.com/norwegianredcross/devcontainer-toolbox) and select compare & pull request. Enter a description for the PR and select reviewers so that they can verify your code before merging.
12. When the code is merged jump back to your local main branch and pull from remote so the two branches are in sync.
    -  `git checkout main`
    -  `git pull upstream main`

## How to update a pull request

Sometimes you want to make changes to your PR before it's merged. In github there is a function called draft pull request which will set it on hold so that you can continue working on it and making changes before you open it for review. Just navigate to the [norwegian redcross repo](https://github.com/norwegianredcross/devcontainer-toolbox) find your pull request and mark it as draft.

- Jump back to the branch which you opened the pull request with if you're not already there
  - `git checkout some_feat_branch`
- Make some changes you want to update the PR with then stage and commit
  - `git add some_changes_in_some_file.txt`
  - `git commit -m "some decriptive changes"`
- Push the changes to update the pull request. --force-push-with-lease is the safest force command to use because it ensures that someone elses work will not be overwritten. It will not be the case here, but if you were to force push the changes to a branch that someone is working on, the parameter ensures that it will only push the changes if there is no conflict.
  - `git push --force-with-lease`
- If you navigate back to your pull request in github you will se that it has been updated.

## Rebase

If you have many small commits in a PR it can be hard to follow and the tree will get a bit disorganized, especially if there are many small commits that relates to the same feature or fix. To keep the directory tree clean it's often a good idea to squash smaller commits into one commit. To do this we use rebase with squash and if you want to change the descriptive text of a commit you can use something called reword. All of the different rebase functions is described in the editor when you rebase interactively. Let's say you want to squash the latest three commits into one big commit.

- First check your latest three commits with git log or git reflog. You want to get a hold of the hash in the last three commits backwards.
  - `git reflog`
- This will open an editor and you will see three lines with "pick" in front of them. If you want to squash the two last commits into the first one, let pick stand and replace the other two commits with "s" or "squash". This will merge the two commits into the first one. Save the file and continue with rebase. If you regret and don't want to rebase it's easy to abort, just delete all of the commit lines, save and the file and exit, the rebase will be aborted.
  - `git rebase -i 4f54364`
- When the rebase is done you can push your changes
  - `git push --force-with-lease`
- An easier way to rebase instead of getting the hash first is to use HEAD~3 which will get the latest three commits. Squash your commits as before and continue with pushing your changes.
  - `git rebase -i HEAD~3`
