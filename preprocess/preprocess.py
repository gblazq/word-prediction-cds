#! /usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function, division
from random import seed, random
from math import log
import re
import sqlite3 as lite

numbers_re = re.compile('[0-9]+') # Compile the regular expression for numbers
non_ascii_re = re.compile('[^a-zA-Z0-9. \-\'!\?]+')
dots_re = re.compile('\.+ ')
num = ' ##NUMBER## ' # Replacement string
start = '##START## '
end = ' ##END##'

def processLine(line):
    line = line.decode('utf-8')
    line = line.lower()
    line = non_ascii_re.sub('', line) # Remove punctuation
    line = start + line # + end
    line = numbers_re.sub(num, line)
    line = dots_re.sub(' ##END## ##START## ', line)
    line = re.sub('[\.|!|\?]+', '', line)
    line = re.split('\s+', line)
    while '' in line:
        line.remove('')
    return line

if __name__ == '__main__':
    # Open the files
    try:
        fblogs = open('data/en_US/en_US.blogs.txt', 'r')
        fnews = open('data/en_US/en_US.news.txt', 'r')
        ftwitter = open('data/en_US/en_US.twitter.txt', 'r')
    except IOError:
        print('The script and the data directory must be in the same folder')
        print('Data is supposed to be at data/en_US/')

    # Read the badwords file
    badwords_file = open('badwords.txt', 'r')
    badwords = [word.rstrip() for word in badwords_file]

    words_file = open('words.txt', 'r')
    all_words = [word.decode('utf-8').rstrip().lower() for word in words_file]

    # Open the SQlite connection
    con = lite.connect('ngrams.db')
    
    p = 0.2 # Probability of selecting a line
    seed(2662) # Reproducibility
    
    # Process the files and count the occurrences of each n-gram
    unigrams_counts, bigrams_counts, trigrams_counts = {}, {}, {}
    tetragrams_counts = {}
    counts = [unigrams_counts, bigrams_counts, trigrams_counts, tetragrams_counts]
    for f in [fblogs, fnews, ftwitter]:
        for line in f:
            if random() < p:
                line = processLine(line)
                for n in xrange(1, 5):
                    for i in xrange(len(line) - n + 1):
                        try:
                            counts[n-1][' '.join(line[i:i+n])] += 1
                        except KeyError:
                            counts[n-1][' '.join(line[i:i+n])] = 1
            else:
                pass

    # Word to integers
    word_table = {word:i for i, word in enumerate(unigrams_counts.iterkeys())}
    for word in all_words:
        if not word_table.has_key(word) and word not in badwords:
            word_table[word] = len(word_table) 

    # We need to provide a list of tuples to cur.executemany
    bigrams, trigrams, tetragrams = [], [], []
    ngrams = [bigrams, trigrams, tetragrams]
    minprob = (2e-7, 2e-7, 2e-7)
    for n in xrange(len(counts) -1, 0, -1):
        total = sum(counts[n].values())
        for key in counts[n]:
            obs = counts[n][key]
            prob = obs/total
            if prob > minprob[n-1]:
                keys = key.split(' ')
                if keys[-1] in badwords:
                    continue
                keys = tuple(word_table[w] for w in keys)
                ngrams[n-1].append(keys + (obs/counts[n-1][key.rsplit(' ',1)[0]],))
    
    total_unigrams = sum(unigrams_counts.values())
    unigrams = [(word_table[key], value/total_unigrams) for key, value in unigrams_counts.iteritems() if
    key not in badwords and value/total_unigrams > 2e-6 and key in all_words]
    for word in word_table.iterkeys():
        if not unigrams_counts.has_key(word):
            unigrams.append((word_table[key], 0))

    with con:
        cur = con.cursor()
        
        cur.execute('DROP TABLE IF EXISTS words')
        cur.execute('CREATE TABLE words(word TEXT, int INTEGER)')
        cur.executemany('INSERT INTO words VALUES(?, ?)', word_table.iteritems())

        cur.execute('DROP TABLE IF EXISTS unigrams')
        cur.execute('CREATE TABLE unigrams(w0 INTEGER, prob REAL)')
        cur.executemany('INSERT INTO unigrams VALUES(?, ?)', unigrams)

        cur.execute('DROP TABLE IF EXISTS bigrams')
        cur.execute('CREATE TABLE bigrams(w1 INTEGER, w0 INTEGER, prob REAL)')
        cur.executemany('INSERT INTO bigrams VALUES(?, ?, ?)', bigrams)
  
        cur.execute('DROP TABLE IF EXISTS trigrams')
        cur.execute('CREATE TABLE trigrams(w2 INTEGER, w1 INTEGER, w0 INTEGER, prob REAL)')
        cur.executemany('INSERT INTO trigrams VALUES(?, ?, ?, ?)', trigrams)

        cur.execute('DROP TABLE IF EXISTS tetragrams')
        cur.execute('CREATE TABLE tetragrams(w3 INTEGER, w2 INTEGER, w1 INTEGER, w0 INTEGER, prob REAL)')
        cur.executemany('INSERT INTO tetragrams VALUES(?, ?, ?, ?, ?)', tetragrams)

        con.commit()

    fnews.close()
    ftwitter.close()
    fnews.close()
