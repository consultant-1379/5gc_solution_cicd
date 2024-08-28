This project is used by 5gc solution cicd teams. It is used to store 5gc cicd deployment configuration files, certification files and scripts.

There is directory structure and file names proposal should be followed when there is new platform or pod introduced to the Repo. It's always
good to get reference from nfvi/n84.

Here is the proposed directory structure:

<platform>/<pod-name>/
                     ├── certs    (Store all the certification files)
                     │   ├── cnf
                     │   │   ├── <cnf-typeX>
                     │   │       ...
                     │   ├── common    (Store all the shared certification files)
                     │   └── evnfm     (Store evnfm certification files)
                     ├── cnf
                     │   ├── <cluster-nameX>
                     │       ├── <cnf-typeX>
                     │           ├── <versionX>
                     │               ├── day0    (Store configuration files for instatiate like values.yaml, instatiate.json)
                     │               ├── day1    (Store configuration files to config the CNF)
                     ├── dallas
                     ├── eccd
                     ├── evnfm

                     
