rgviz-rails
===========

[![Build Status](https://secure.travis-ci.org/asterite/rgviz-rails.png?branch=master)](http://travis-ci.org/asterite/rgviz-rails)

This library makes it easy to implement a visualization data source so that you can easily chart or visualize your data from [ActiveRecord](http://ar.rubyonrails.org/) models or from in-memory arrays. the library implements the [Google Visualization API wire protocol](http://code.google.com/apis/visualization/documentation/dev/implementing_data_source.html).

It also allows you to [render the visualizations in a view template](https://github.com/asterite/rgviz-rails/wiki/showing-a-visualization-in-a-view) in a very simple but powerful way.

This library is built on top of [rgviz](https://github.com/asterite/rgviz).

Installation
------------

    gem install rgviz-rails

Rails 3
-------

In your gemfile

    gem 'rgviz'
    gem 'rgviz-rails', :require => 'rgviz_rails'

Rails 2.x
---------

In your environment.rb

    config.gem "rgviz"
    config.gem "rgviz-rails", :require => 'rgviz_rails'

Usage
-----

To make a method in your controller be a visualization api endpoint:

    class VizController < ApplicationController
      def person
        # Person is an ActiveRecord::Base class
        render :rgviz => Person
      end
    end

So for example if <ttPperson</tt> has <tt>name</tt> and <tt>age</tt>, pointing your browser to:

    http://localhost:3000/viz/person?tq=select name where age > 20 limit 5

would render the necessary javascript code that implements the google visualization api wire protocol.

Associations
------------

If you want to filter, order by or group by columns that are in a model's association you can use underscores. this is better understood with an example:

    class Person < ActiveRecord::Base
      belongs_to :city
    end

    class City < ActiveRecord::Base
      belongs_to :country
    end

    class Country < ActiveRecord::base
    end

To select the name of the city each person belongs to:

    select city_name

To select the name of the country of the city each person belongs to:

    select city_country_name

A slightly more complex example:

    select avg(age) where city_country_name = 'argentina' group by city_name

The library will make it in just one query, writing all the sql joins for you.

Extra conditions
----------------

Sometimes you want to limit your results the query will work with. You can do it like this:

    render :rgviz => Person, :conditions => ['age > ?', 20]

or also:

    render :rgviz => Person, :conditions => 'age > 20'

Preprocessing
-------------

If you need to tweak a result before returning it, just include a block:

    render :rgviz => Person do |table|
      # modify the Rgviz::Table object
    end

Showing a visualization in a view
---------------------------------

You can invoke the rgviz method in your views. [read more about this](https://github.com/asterite/rgviz-rails/wiki/showing-a-visualization-in-a-view).

You can always do it the [old way](https://developers.google.com/chart/interactive/docs/examples#full_html_page_example).

Executing queries over in-memory arrays
---------------------------------------

You can also apply a query over an array of arrays that contains your "records" to be queried.

    types = [[:id, :number], [:name, :string], [:age, :number]]
    records = [
      [1, 'john', 23],
      [2, 'pete', 36]
    ]
    executor = Rgviz::MemoryExecutor.new records, types

    render :rgviz => executor

This is very useful if you need to present visualizations against data coming from a csv file.

Virtual columns
---------------

GQL is nice but it's not very powerful (except for the cute pivot clause).

If you need to select columns using complex SQL, you might be able to do it with virtual columns.

For example, in your controller you put:

    render :rgviz => Person, :virtual_columns => {
        'age_range' => {
            :sql => "case when age < 20 then 'young' else 'old' end", 
            :type => :string
        }
    }

Then in a query you can do:

select age_range ...

Note that the keys of the virtual_columns hash must be strings. The value can be a hash with :sql and :type key-value pairs (since GQL needs the type of every column), or can be just a string if you want the column to be replaced by another GQL expression. For example:

    render :rgviz => Person, :virtual_columns => {
        'age_plus_two' => 'age + 2'
    }

Current limitations
-------------------

* the *format* clause works, but formatting is as in ruby (like "%.2f" for numbers, "foo %s bar" for strings, and "%y-%m-%d" for dates, as specified by [Time#strftime](http://www.ruby-doc.org/core-1.9.3/Time.html#method-i-strftime))
* only supports mysql, postgresql and sqlite adapters
* these scalar functions are not supported for sqlite: *millisecond*, *quarter*
* these scalar functions are not supported for mysql: *millisecond*
* the function *toDate* doesn't accept a number as its argument
* the *tsv* output format is not supported

Contributors
------------

* [Brad Seefeld](https://github.com/bradseefeld)