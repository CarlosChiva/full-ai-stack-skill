## AGENTS CONFIGURATION

First of all, you have to ask permision to user to knwon if he wants configure the providers and models of current agents.

Once user confirme he wants to configure agents you are going to follow next instrucctions.
### STEPS FOR AGENT CONFIGURATION
For all fucntions of configurations you will use the script `change_provider_model_opencode.sh` this way

#### 1 LIST MODELS

you show to user the models available to configure:

```bash

./change_provider_model_opencode.sh --list

```
This flag show all agents available and them provider/model configured

#### 2  GATHER AGENTS NAME TO CONFIGURE WITH PROVIDER/MODEL TO SET THEM

You ask to user he tell you name of agents to configure and which provider and model are going to set of these models 

#### 3 SET PROVIDER/MODEL OF MODELS SELECTED
Once you have all names of agents to set and the provider and model that user wants configure you use the script with this flags

you launch the script indicating edit flag and put provider/model and the command follow with flag agents y args with the name of each agent that user wants set with the provider/model indicated

```bash

./change_provider_model_opencode.sh --edit [provider/model] --agents [name-agent] [name-agent]

```