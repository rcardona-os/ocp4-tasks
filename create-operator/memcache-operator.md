- install dependencies
> $ wget https://dl.google.com/go/go1.20.2.linux-amd64.tar.gz
>
> $ sha256sum go1.20.2.linux-amd64.tar.gz
>
> mkdir ${HOME}/opt
>
> tar -C ${HOME}/opt -xzf go1.20.2.linux-amd64.tar.gz
>
> $ curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
>
> $ sudo mv ${HOME}/go/bin/dep /usr/local/go/bin/
>
>
>


sudo mv /home/raf/go/bin/dep /usr/local/go/bin/