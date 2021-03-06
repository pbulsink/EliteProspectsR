#' EliteProspects Caller
#'
#' @param path Path Components of API call
#' @param params Filter or other parameters of API call
#'
#' @return The response from the API call built with path and params
eliteprospects_api <- function(path, params=list()) {
  if(is.null(path) || is.na(path) || !is.character(path) || path==''){
    stop("API Call requires character path", .call=FALSE)
  }
  params<-c(params, 'apikey'=get_api_key())
  path<-paste0("beta/", path)
  url <- httr::modify_url("http://api.eliteprospects.com/", path=path, query = params)
  httr::user_agent(get_user_agent())
  resp<-httr::GET(url)

  if(httr::http_type(resp) != "application/json") {
    stop("API did not return json", call. = FALSE)
  }

  if (httr::http_error(resp)) {
    stop(
      sprintf(
        "EliteProspects API request failed (%s)",
        httr::status_code(resp)
      ),
      call. = FALSE
    )
  }

  parsed<-jsonlite::fromJSON(httr::content(resp, "text"), simplifyVector = FALSE)

  if('status' %in% parsed && parsed$status == 'error'){
    stop(cat("API provided error(s):", parsed$messages[[1]], sep="\n"), call. = FALSE)
  }

  structure(list(content = parsed, path=path, response = resp), class = "eliteprospects_api")
}

print.eliteprospects_api <- function(x, ...) {
  cat("<EliteProspects ", x$path, ">\n", sep="")
  utils::str(x$content)
  invisible(x)
}

#' Process Filters
#'
#' @param filters The filter(s) to process
#'
#' @return properly formatted filter(s)
process_filters<-function(filters){
  filter<-paste0(names(filters[1]),"=",filters[[1]])
  if(length(filters)>1){
    for(i in 2:length(filters)){
      filter<-paste0(filter, ",", names(filters[i]),"=",filters[[i]])
    }
  }
  #filter<-utils::URLencode(filter, reserved=TRUE)
  filter<-list("filter"=filter)
  return(filter)
}

#' Process sorts
#'
#' @param sorts The sort(s) to process
#'
#' @return properly formatted sort(s)
process_sorts<-function(sorts){
  sort<-paste0(names(sorts[1]), ":", sorts[[1]])
  if(length(sorts)>1){
    for(i in 2:length(sorts)){
      sort<-paste0(sort, ",", names(sorts[i]), ":", sorts[[i]])
    }
  }
  #sort<-utils::URLencode(sort, reserved=TRUE)
  sort<-list("sort"=sort)
  return(sort)
}

#' Process fields
#'
#' @param fields The field(s) to process
#'
#' @return properly formatted field(s)
process_fields<-function(fields){
  field<-paste0(fields,collapse=",")
  field<-list('fields'=field)
  return(field)
}

#' Process types
#'
#' @param types The type(s) to process
#'
#' @return properly formatted type(s)
process_types<-function(types){
  type<-paste0(types,collapse=",")
  type<-list('type'=type)
  return(type)
}

#' Process limit
#'
#' @param limit The limit to process
#'
#' @return properly formatted limit
process_limit<-function(limit){
  if(is.numeric(limit) & length(limit)==1){
    return(list("limit"=limit))
  } else {
    stop("Provide only a single numerical limit value")
  }
}

#' Process offset
#'
#' @param offset The offset to process
#'
#' @return properly formatted offset
process_offset<-function(offset){
  if(is.numeric(offset) & length(offset)==1){
    return(list("offset"=offset))
  } else {
    stop("Provide only a single numerical offset value")
  }
}

#' Process minScore
#'
#' @param minScore The minScore to process
#'
#' @return properly formatted offset
process_minScore<-function(minScore){
  if(is.numeric(minScore) & length(minScore)==1){
    return(list("minScore"=minScore))
  } else {
    stop("Provide only a single numerical minScore value")
  }
}

#' Process Parameters for API searches
#'
#' @param types type(s) to process, or NULL
#' @param filters filter(s) to process, or NULL
#' @param sorts sort(s) to process, or NULL
#' @param fields field(s) to process, or NULL
#' @param limit limit to process, or None
#' @param offset offset to process, or None
#' @param minScore minScore to process, or None
#'
#' @return properly formatted parameters
process_search_params<-function(types = NULL, filters=NULL, sorts=NULL, fields = NULL, limit=0, offset=0, minScore=0){
  params<-list()
  if(!is.null(types)) params<-c(params, process_types(types))
  params <- c(params, process_params(filters = filters, sorts = sorts, fields = fields, limit = limit, offset = offset))
  if(minScore != 0) params <- c(params, process_minScore(minScore))
  params
}

#' Process Parameters for API call building
#'
#' @param filters filter(s) to process, or NULL
#' @param sorts sort(s) to process, or NULL
#' @param fields field(s) to process, or NULL
#' @param limit limit to process, or None
#' @param offset offset to process, or None
#'
#' @return properly formatted parameters
process_params<-function(filters=NULL, sorts=NULL, fields = NULL, limit=0, offset=0){
  params<-list()
  if(!is.null(filters)) params<-c(params, process_filters(filters))
  if(!is.null(sorts)) params<-c(params, process_sorts(sorts))
  if(!is.null(fields)) params<-c(params, process_fields(fields))
  if(limit != 0) params<-c(params, process_limit(limit))
  if(offset != 0) params<-c(params, process_offset(offset))
  params
}

#' basic list request handler
#'
#' @param path The path to get a list of
#' @param filters Any filters to apply
#' @param sorts Any sorting to apply to results
#' @param fields Specific fields to retrieve
#' @param limit Maximum number of results returned
#' @param offset Offset of returned results
#'
#' @return the results of the built API call
simple_list <- function(path, filters=NULL, sorts=NULL, fields=NULL, limit=0, offset=0){
  if(is.null(filters) && is.null(sorts) && is.null(fields)){
    stop("Please include some query information")
  }

  params <- process_params(filters, sorts, fields, limit, offset)

  result<-eliteprospects_api(path, params)
  return(result$content$data)
}

#' Base simple get handler
#'
#' @param path The path to get from
#' @param id The specific ID to get
#' @param filters Any filters to apply
#' @param sorts Any sorting to apply to results
#' @param fields Specific fields to retrieve
#' @param limit Maximum number of results returned
#' @param offset Offset of returned results
#'
#' @return the results of the built API call
simple_get <- function(path=NULL, id=NULL, filters=NULL, sorts=NULL, fields=NULL, limit=0, offset=0){
  if(is.null(path) || is.null(id)){
    stop("Please include the query information")
  }
  path<-paste0(path, id)

  params <- process_params(filters, sorts, fields, limit, offset)

  result<-eliteprospects_api(path, params)
  return(result$content$data)
}

#' Base simple search handler
#'
#' @param path The path to get from
#' @param query The specific query to search for
#' @param types Any limit on type to return
#' @param filters Any filters to apply
#' @param sorts Any sorting to apply to results
#' @param fields Specific fields to retrieve
#' @param limit Maximum number of results returned
#' @param offset Offset of returned results
#' @param minScore Minimum score of search results
#'
#' @return the results of the built API call
simple_search <- function(path=NULL, query=NULL, types = NULL, filters=NULL, sorts=NULL, fields=NULL, limit=0, offset=0, minScore=0){
  if(is.null(path) || is.null(query)){
    stop("Please include the query information")
  }
  path<-paste0(path)
  params<-list('q'=query)
  params <- c(params, process_search_params(types = types, filters=filters, sorts=sorts, fields=fields, limit=limit, offset=offset, minScore=minScore))

  result<-eliteprospects_api(path, params)
  return(result$content)
}

#' Base nested/layered get handler
#'
#' @param path The path to get from
#' @param id The specific ID to get
#' @param item The subset/nest item to get
#' @param filters Any filters to apply
#' @param sorts Any sorting to apply to results
#' @param fields Specific fields to retrieve
#' @param limit Maximum number of results returned
#' @param offset Offset of returned results
#'
#' @return the results of the built API call
layered_get <- function(path=NULL, id=NULL, item=NULL, filters=NULL, sorts=NULL, fields=NULL, limit=0, offset=0){
  if(is.null(path) || is.null(id) || is.null(item)){
    stop("Please include the query information")
  }

  path<-paste0(path, "/", id, "/", item, "/")

  params <- process_params(filters = filters, sorts = sorts, fields = fields, limit = limit, offset = offset)

  result<-eliteprospects_api(path, params)
  return(result$content$data)
}
