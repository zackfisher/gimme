#' Convolve data.
#'
#' @param ts_list a list of dataframes.
#' @param varLebels a list of variable sets.
#' @param conv_length Expected response length in seconds. For functional MRI BOLD, 16 seconds (default) is typical
#' for the hemodynamic response function. 
#' @param conv_interval Interval between data acquisition. Currently must be a constant. For 
#' fMRI studies, this is the repetition time. Defaults to 1. 
#' @keywords internal
setupConvolve <- function(ts_list = NULL, varLabels = NULL, conv_length = 16, conv_interval = 1){
  
  # We only convolve contemporaneous (lagged contemporaneous created afterwards). 
  to_convolve <- setdiff(varLabels$coln, c(varLabels$conv, varLabels$exog))
  
  ts_list <- lapply(ts_list, function(df){
    
    conv_use  <- df[,to_convolve, drop = FALSE]
    
    if(any(apply(conv_use, 2, function(x) any(is.na(x) | is.infinite(x))))){
      
      conv_use[]  <- apply(conv_use, 2, function(x) { imputeTS::na.kalman(ts(x)) })
      
    }
    
    for (cv in varLabels$conv){
      
      stimuli   <- df[,cv, drop = TRUE]
      
      if(any(is.na(stimuli))){
        stop(
          "gimme ERROR: missing values in conv_vars not allowed"
        )
      }
      
      convolved <- sFIR(data = conv_use, stimuli = stimuli, response_length = conv_length, interval = conv_interval)
      
      df[,cv]   <- convolved$conv_stim_onsets[1:nrow(df)]

    }
    
    df

  })
    
  return(ts_list)
  
}