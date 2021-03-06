load_config_and_settings <- local({
  #only do this once per package load
  opencpu_is_initiated = FALSE

  #actual function
  function(preload = FALSE){
    if(isTRUE(opencpu_is_initiated)){
      return();
    } else {
      opencpu_is_initiated <<- TRUE
    }

    #load default package config file
    defaultconf <- system.file("config/defaults.conf", package = packagename)
    stopifnot(file.exists(defaultconf))
    environment(config)$load(defaultconf)

    #override with system config file
    sysconf <- get_user_conf()
    if(file.exists(sysconf)){
      environment(config)$load(sysconf)
    }

    #override with system config file
    if(is_rapache() || is_admin()){
      #override with custom system config files
      if(isTRUE(file.info("/etc/opencpu/server.conf.d")$isdir)){
        conffiles <- list.files("/etc/opencpu/server.conf.d", full.names=TRUE, pattern=".conf$")
        lapply(as.list(conffiles), environment(config)$load)
      }
    } else {
      # clean remenants from opencpu 1.0
      unlink(path.expand("~/.opencpu.conf"))
    }

    # global options. This should be moved into the fork/worker process
    options(max.print = 1000)
    options(menu.graphics = FALSE)
    options(keep.source = FALSE)
    options(useFancyQuotes = FALSE)
    options(warning.length = 8000)
    options(scipen = 3)

    #options(device=grDevices::pdf); # now set before eval_safe()

    # Set a default repository
    if(!length(getOption('repos')))
      options(repos=config('repos'))

    #use cairo if available
    if(!identical(getOption("bitmapType"), "cairo") && isTRUE(capabilities()[["cairo"]])){
      options(bitmapType = "cairo")
    }

    #load custom pkgs but avoid the old packages from '/usr/lib/opencpu/library'
    if(isTRUE(preload)){
      for(thispackage in config("preload")){
        try(getNamespace(thispackage), silent=TRUE);
      }
    }
  }
})
