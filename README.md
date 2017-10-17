# Word prediction web app

This is my project for the Coursera's Data Science specialization capstone course.

The project had to be a Shiny application that predicts the next word in a sentence,
trained with a dataset of Twitter, blog posts and other texts. The dataset was provided
by SwiftKey.

## The app
### The Shiny app can be found [here](https://gblazq.shinyapps.io/word_prediction/)

It predicts the 3 most likely next words in a sentence and the 3 most likely words that the user
is typing. There is the option to output only a single word in order to comply with the project's
requirements.

## The model
Predictions are done using 1, 2, 3 and 4-grams (an n-gram is a group of n words found in a text).
The algorithm tries to use the most likely 4-gram given the user's input. If there is no 4-gram, it
finds the most likely 3-gram, and so forth until the 1-grams.

Words and sentences are preprocessed to remove certain punctuation marks, append start and end of
sentence strings, convert to lowercase and other operations.

## How the app works
The preprocess/preprocess.py script creates the SQLite database. It uses a list of English words, badwords
that shouldn't be included in the outputs (project requisites) and the raw data. The data is not
included in the repository, it must be in a directory named data/en\_US and there must be three files:
* en\_US.blogs.txt
* en\_US.news.txt
* en\_US.twitter.txt

The script selects a random sample of each file and computes the probabilities of every 1 to 4-gram.
All 1-grams with probability > 1E-6 and all 2, 3, and 4-grams with P > 1E-7 are stored in the database. 
To increase the performance, all words are hashed and a hash table is also stored in the same database.

The SQLite database is deployed with the Shiny app. The database is loaded to an R data table when the app
starts and all searches are done in the data tables, which are way faster than the database.

When the user changes the input, the app searches for the 3 most likely words. If there is an space
character after the last word, it searches for the most likely next words. If there isn't any space,
it searches for the most likely words completing the last word.

## More info
There is an exploratory data analysis in EDA.html. A brief presentation of the app can be found
[here](http://gblazq.github.io/word-prediction-cds/index.html)

