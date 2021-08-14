This project is intended to be a public location for some common pipeline automation. The scripts are generally derived from this common template: [_template.sh](https://gist.github.com/natemarks/aebb7e84010d4bc37270d554106cb38b) The scripts execute configuration steps run inside a pipeline.  They allow pipeline steps to setup and run various versions of the downloaded tools. It also avoids having to maintain the tools in the agent image. Downlaods should be placed in locations that persist across jobs.  The agent ${HOME} might be a good location.

## Go  - Don't install it
The go installation can be a bit complicated.  I prefer to use the go docker image to do go builds in my pipeline.  I ahve a Make target that looks like this and it's run on the agen. It just requires that the docker engine is installed on the agent:

```makefile
build:
	docker run --rm -i -v "${PWD}":/usr/src/myapp \
	-w /usr/src/myapp my_golang:latest go build -v -o $(EXECUTABLE); \
	find . -type f -name $(EXECUTABLE) -print
	zip $(EXECUTABLE).zip $(EXECUTABLE)
```

## scripts/install_terraform.sh
Install a specific version of the terraform executable to a specific directory.


## scripts/install_terragrunt.sh
Install a specific version of the terragrunt executable to a specific directory. 


## TBD: packer
Install a specific version of the terragrunt executable to a specific directory. 

