# lemonade

Creating websites should be as easy as making lemonade - gather your ingredients, follow a simple process and enjoy!

`lemonade` creates static, minified and compressed websites using Hugo, Caddy and RealFaviconGenerator which can deployed by rsync to any Linux host or container with no additional dependencies (not even an installed webserver). All the inputs to the website can be stored in git. Websites can also run locally on any operating system that Caddy supports.

`lemonade` understands about environments (eg production) and lets you separate out the small pieces of configuration (and any secrets) that need to differ.

## To use

### Preparation

Create a new git repository and add lemonade as a submodule:-

```bash
mkdir my-site
cd my-site
git init
mkdir tools
cd tools
git submodule add https://github.com/raphaelcohn/lemonade.git
cd ..
cd ..
mkdir -p input

printf '%s\n' 'output/' >.gitignore
```

You'll need to set up a folder structure inside `input`. This step will be documented once lemonade is stable and used by more than a simple site.


### Creating a Static Website

From the root of your repository, do:-

```bash
tools/lemonade/lemonade --input-path ./input --output-path ./output
```

Your website, including Caddy and all dependencies, can then be deployed simply by doing `rsync --archive --quiet ./output/site/ USER@REMOTE_SERVER:/path/to/remote/host`.

You can then start your website by doing `./download-caddy serve production` from inside `./output/site`.

If `caddy` is already running on the remote host, you can tell it to reload with `ssh USER@REMOTE_SERVER kill -SIGUSR1 PID`. However, given that some changes may not be to configuration, it is probably best to restart.

The documentation of this step will be improved following operational experience.


## License

lemonade is MIT licensed. Caddy, Hugo and Jq are not part of the license of lemonade.
