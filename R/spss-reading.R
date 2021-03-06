
get.codes <- function(tab)
{
    labels   =  tab %>% memisc::labels(.)
    missings =  tryCatch(
       tab %>% memisc::missing.values(.),
       error = function(e) {NULL}
    )
    if (!is.null(labels)) {
        tab = tryCatch(
            labels %>% tibble::tibble (code   = slot(., "values"),
                                       label = slot(., ".Data"),
                                       ) %>%
            dplyr::select(code, label),
            error = function(e) {NULL}
        ) 
    }else{
       tab = NULL
    }
    if (!is.null(missings) & !is.null(tab)) {
        missing.range   = missings  %>% slot(., "range") %>% as.numeric
        missing.filter  = missings  %>% slot(., "filter") %>% as.numeric
        if (length(missing.range )>0 & !is.null(missing.range )) {missing = missing.range}
        if (length(missing.filter)>0 & !is.null(missing.filter)) {missing = missing.filter}
        tab =  tab %>%
            dplyr::mutate(code.for.missing = dplyr::case_when(code %in%  missing ~ "yes",
                                                              code %!in% missing ~ "no",
                                                              )
                          )  %>%
            dplyr::select(code, label) 
    }
    if (is.null(missings) & !is.null(tab)) {
        tab =  tab %>%
            dplyr::mutate(code.for.missing = NA_real_)  %>%
            dplyr::select(code, label) 
    }
    return(tab)
}

get.cb.labels <- function(spss)
{
    options(warn=-1)
    on.exit(options(warn=0))
    
    varnames = slot(spss, "names")
    desc     = slot(spss, ".Data") %>%
        purrr::map(.x=., function(.x) .x  %>% memisc::annotation(.) %>% as.character ) %>%
        unlist(.)
    coding   = slot(spss, ".Data") %>% purrr::map(.x=., function(.x) get.codes(.x)) 
    
    tab = tibble::tibble(var = varnames,
                         desc = desc,
                         coding = coding) 
    ## if (!is.null(spss@stats$tab)) {

    ##     missings  = spss@spec['Missing values:'] %>% stringr::str_split(string=., pattern=",", simplify=TRUE) %>% as.numeric
    ##     tab = spss@stats$tab %>% 
    ##         as.data.frame(.) %>%
    ##         tidyr::spread(., key=Var2, value=Freq) %>%
    ##         tibble::as_tibble(.)  %>% 
    ##         dplyr::rename_at(vars(1:3), ~paste0(c("label", 'counts', 'freq')) ) %>%
    ##         tidyr::separate(., col=label, into=c("code", "label"), sep=" \'")  %>%
    ##         tidyr::separate(., col=code , into=c("code", "missing"), sep="M") %>%
    ##         dplyr::mutate(code = stringr::str_replace_all(string=code , pattern="[a-z]|[A-Z]", replacement="") %>%
    ##                           stringr::str_trim(.) %>% as.numeric,
    ##                       label = stringr::str_trim(label)  %>% stringr::str_replace(string=., pattern="\'$", replacement=""),
    ##                       missing = dplyr::case_when(!is.na(missing)~"yes",
    ##                                                  is.na(missing)~"no")
    ##                       ) %>%
    ##         dplyr::select(code, missing, label, dplyr::everything()) 
    ##     ## tab = spss@stats$tab %>% 
    ##     ##     tibble::as_data_frame()  %>% 
    ##     ##     dplyr::rename_at(vars(1:3), dplyr::funs(c("label", 'stat', 'freq')) ) %>% 
    ##     ##     tidyr::spread(., key=stat, value=freq) %>%
    ##     ##     tidyr::separate(., col=label, into=c("code", "label"), sep=" '")  %>%
    ##     ##     dplyr::mutate(label = stringr::str_replace_all(string=label, pattern="^'|' |'$", replacement="") %>% stringr::str_trim(.),
    ##     ##                   code = stringr::str_replace(string=code , pattern="M", replacement="") %>% stringr::str_trim(.) %>% as.numeric,
    ##     ##                   `missing` = dplyr::case_when(code %in% missings ~ 'yes', TRUE ~ 'no')) %>%
    ##     ##     dplyr::select(code, missing, label, dplyr::everything()) 
    ## }else{
    ##     tab = NULL
    ## }

    return(tab)
}

## {{{ docs }}}
#' Get codebook
#'
#' Get information about variables from a SPSS (.sav) file
#'
#' @param x a S4 object returned by \code{memisc::spss.system.file}
#' @return Returns a tibble data frame with variable names, label, and the coding used for the categorical variables, which include summary statistics for each catagory
#'
#' @export
## }}}
get.cb <- function(x)
{
    options(warn=-1)
    on.exit(options(warn=0))
    ## Debug/Monitoring message --------------------------
    msg <- paste0('\n','Creating codebook ...',  '\n'); cat(msg)
    ## ---------------------------------------------------
    ## tab = memisc::codebook(x)
    ## tab = tab %>% 
    ##     tibble::tibble(var      = names(.),
    ##                    desc     = purrr::map_chr(.x=.@.Data, function(.x) paste0(.x@annotation@.Data, collapse=' // ') ) %>% stringr::str_trim(.),
    ##                    coding = .@.Data) %>%
    ##     dplyr::mutate(coding = purrr::map(.x=coding, function(.x) get.cb.labels(.x)) ) %>%
    ##     dplyr::select(var, desc, coding) 
    tab = get.cb.labels(x)
    return(tab)
}

## {{{ docs }}}
#' Return tibble with variable coding
#'
#' The function returns a list with the coding scheme of the variables
#'
#' @inheritParams get.cb
#' @param vars string vector with the name of the variables to display the coding scheme used in the data. If \code{NULL} (default), all variables are used.
#'
#' 
#' @export
## }}}
show.coding <- function(x, vars=NULL)
{
    for (var in vars)
    {
        if (var %!in%x$var) {stop(paste0("\nVariable ", var, " not found!") )}
    }
    var.labels =  x %>%
        dplyr::filter(var %in% !!vars)  %>% 
        tidyr::unite(var, desc , col=label, sep="/", remove=TRUE) %>%
        dplyr::select(label)  %>%
        dplyr::pull(.)
    tab =  x %>%
        dplyr::filter(var %in% !!vars)  %>% 
        dplyr::select(coding)  %>%
        dplyr::pull(.)
    names(tab) = var.labels
    return(tab)
}

## {{{ docs }}}
#' Load data from SPSS file
#'
#' The function returns the actual data set from a SPSS object created by the function \code{\link{memisc::spss.system.file()}}
#'
#' @inheritParams get.cb
#'
#' @return Data is returned in a tidy data frame (tibble)
#'
#' @export
## }}}
load.spss <- function(x, vars=NULL)
{
    options(warn=-1)
    on.exit(options(warn=0))

    if (any(!vars %in% names(x))) {
        missing.variables = vars[which(!vars %in% names(x))] 
        stop("\n\n Variables ", paste0("'", paste0(missing.variables, collapse=', ') , "' not in the data") )
    }

    ## Debug/Monitoring message --------------------------
    msg <- paste0('\n','Creating tidy data.frame (tibble)...',  '\n'); cat(msg)
    ## ---------------------------------------------------
    
    if (is.null(vars)) {
        dat = memisc::subset(x) %>% 
            purrr::map(.x=., function(.x) .x %>% c)
    }else{
        dat = memisc::subset(x, select=vars) %>% 
            purrr::map(.x=., function(.x) .x %>% c)
    }
    dat = dat %>%
        tibble::as_data_frame(.) 
    return(dat)
}
