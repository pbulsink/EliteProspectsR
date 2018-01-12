#' Get API Key
#'
#' @description Returns the API key entered in set_api_key.
#'
#' @return API key set by set_api_key
#' @family API functions
#' @seealso \code{\link{set_api_key}} for setting the API key
#' @export
get_api_key <- function(){
  api <- Sys.getenv('ELITEPROSPECTS_API')
  if (identical(api, "")) {
    stop("Please set your API key with set_api_key([api_key_value])",
         call. = FALSE)
  }
  api
}

#' Set API Key
#' @description API keys can be obtained by following the instructions at \url{https://github.com/menmo/eliteprospects-api-documentation}
#' @param new_api_key API key string from eliteprospects.
#'
#' @family API functions
#' @seealso \code{\link{get_api_key}} for getting the API key
#' @export
#'
#' @examples
#' set_api_key('123abc')
set_api_key<-function(new_api_key="DEFAULT_API"){
  if(is.null(new_api_key) || is.na(new_api_key) || !is.character(new_api_key)){
    stop("API must be alphanumeric string.")
  }
  Sys.setenv('ELITEPROSPECTS_API' = new_api_key)
}