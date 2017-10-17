library(shiny)
library(RSQLite)
library(plyr)
library(dplyr)
library(stringi)
library(data.table)

database <- 'ngrams.db'
if(file.exists(database)){
    con = dbConnect(drv = SQLite(), dbname = database)
} else {
    stop('Database not found')
}

tetragrams <- data.table(dbGetQuery(con, "SELECT * FROM tetragrams;"))
trigrams <- data.table(dbGetQuery(con, "SELECT * FROM trigrams;"))
bigrams <- data.table(dbGetQuery(con, "SELECT * FROM bigrams;"))
unigrams <- data.table(dbGetQuery(con, "SELECT * FROM unigrams;"))
words <- data.table(dbGetQuery(con, "SELECT * FROM words;"))

setkey(tetragrams, w3, w2, w1)
setkey(trigrams, w2, w1)
setkey(bigrams, w1)

process_line <- function(string) {
    string <- tolower(string)
    string <- gsub('[^a-zA-Z0-9. \\-\'!\\?]+', '', string, perl=TRUE)
    string <- paste('##START## ', string)
    string <- gsub('[0-9]+', ' ##NUMBER##', string)
    string <- gsub('[\\.|!|\\?]+ ', ' ##END## ##START## ', string)
    string <- gsub('\\.+', ' ', string)
    split_string <- unlist(strsplit(string, '[[:space:]]+'))
    if ( grepl(' $', string) ) {
        split_string[[length(split_string)]] <- paste(tail(split_string, 1), ' ', sep='')
    }
    tail(split_string, 4)
}

get_next_words <- function(processed_line, n, valid_ints = NULL) {
    last_word <- tail(processed_line, 1)
    if( length(last_word) == 0 ){
        return(unigrams[,][order(-prob)][1:3,])
    }
    if( stri_endswith_fixed(last_word, ' ') ) {
        if( empty(words[word == stri_trim_right(last_word),]) ){
            return(unigrams[,][order(-prob)][1:3,])
        }
        ints <- lapply(c(head(processed_line, -1), stri_trim(last_word)), function(x) words[word == x,int])
        ints <- tail(ints, n-1)
        while( any(sapply(ints, function(x) length(x) == 0)) ){
            ints <- tail(ints, -1)
        }
        n <- length(ints) + 1
        next_words <- switch(n,
            unigrams[,][order(-prob)][1:3,],
            bigrams[ints, w0, prob][order(-prob)][1:3,],
            trigrams[ints, w0, prob][order(-prob)][1:3,],
            tetragrams[ints, w0, prob][order(-prob)][1:3,])
    } else {
        if( is.null(valid_ints) ) {
            valid_words <- words[stri_startswith_fixed(word, last_word), ]
            valid_ints <- valid_words[valid_words$int %in% unigrams$w0]$int
            if( length(valid_ints) < 3 ) {
                next_words <- unigrams[w0 %in% valid_ints]
                return(next_words)
            }
        }
        ints <- sapply(c(head(processed_line, -1)), function(x) words[word == x,int], USE.NAMES = FALSE)
        next_words <- switch(n, 
                             unigrams[w0 %in% valid_ints, ][order(-prob)][1:3,],
                             bigrams[w1 == ints[[1]] & w0 %in% valid_ints, w0, prob][order(-prob)][1:3,],
                             trigrams[w2 == ints[[1]] & w1 == ints[[2]] & w0 %in% valid_ints, w0, prob][order(-prob)][1:3,],
                             tetragrams[w3 == ints[[1]] & w2 == ints[[2]] & w1 == ints[[3]] & w0 %in% valid_ints, w0, prob][order(-prob)][1:3,])    
    }
    if( ((!all(complete.cases(next_words))) || (nrow(next_words) < 3)) && (n != 1) ){
        backoff <- get_next_words(tail(processed_line, -1), n-1, valid_ints)
        next_words <- join(next_words, anti_join(backoff, next_words, by="w0"), type="full", by="w0")
    }
    next_words
}

shinyServer(function(input, output) {
    next_words <- reactiveVal(list('I', 'the', 'it'))
    
    observeEvent(input$sentence, {
        sentence <- process_line(input$sentence)
        if( stri_endswith_fixed(tail(sentence, 1), ' ') ){
            n <- min(4, length(sentence) + 1)
        } else {
            n <- min(4, length(sentence))
        }
        next_list <- arrange(get_next_words(sentence, n), -prob)[1:3, ]
        next_list <- unlist(sapply(next_list$w0, function(x) words[int == x, word], USE.NAMES = FALSE))
        while( length(next_list) < 3){
            next_list <- c(next_list, " ")
        }
        next_list <- gsub("^i(\'m|\'ve|\'ll|\'ma)?$", 'I\\1', next_list)
        next_words(next_list)
    })
    
    output$next_word_first <- renderText(next_words()[[1]])
    output$next_word_first2 <- renderText(next_words()[[1]])
    output$next_word_second <- renderText(next_words()[[2]])
    output$next_word_third <- renderText(next_words()[[3]])
})
