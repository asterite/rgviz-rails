rgviz-rails
===========

this library makes it easy to implement a visualization data source so that you can easily chart or visualize your data from [activerecord](http://ar.rubyonrails.org/) models or from in-memory arrays. the library implements the [google visualization api wire protocol](http://code.google.com/apis/visualization/documentation/dev/implementing_data_source.html).

it also allows you to [render the visualizations in a view template](https://github.com/asterite/rgviz-rails/wiki/showing-a-visualization-in-a-view) in a very simple but powerful way.

this library is built on top of [rgviz](https://github.com/asterite/rgviz).

installation
------------

    gem install rgviz-rails

rails 3
-------

in your gemfile

    gem 'rgviz'
    gem 'rgviz-rails', :require => 'rgviz_rails'

rails 2.x
---------

in your environment.rb

    config.gem "rgviz"
    config.gem "rgviz-rails", :lib => 'rgviz_rails'

usage
-----

to make a method in your controller be a visualization api endpoint:

    class vizcontroller < applicationcontroller
      def person
        # person is an activerecord::base class
        render :rgviz => person
      end
    end

so for example if <tt>person</tt> has <tt>name</tt> and <tt>age</tt>, pointing your browser to:

    http://localhost:3000/viz/person?select name where age > 20 limit 5

would render the necessary javascript code that implements the google visualization api wire protocol.

extensions
----------

to enable the extensions defined by rgviz you need to specify it in the render method:

    render :rgviz => person, :extensions => true

associations
------------

if you want to filter, order by or group by columns that are in a model's association you can use underscores. this is better understood with an example:

    class person < activerecord::base
      belongs_to :city
    end

    class city < activerecord::base
      belongs_to :country
    end

    class country < activerecord::base
    end

to select the name of the city each person belongs to:

    select city_name

to select the name of the country of the city each person belongs to:

    select city_country_name

a slightly more complex example:

    select avg(age) where city_country_name = 'argentina' group by city_name

the library will make it in just one query, writing all the sql joins for you.

extra conditions
----------------

sometimes you want to limit your results the query will work with. you can do it like this:

    render :rgviz => person, :conditions => ['age > ?', 20]

or also:

    render :rgviz => person, :conditions => 'age > 20'

preprocessing
-------------

if you need to tweak a result before returning it, just include a block:

    render :rgviz => person do |table|
      # modify the rgviz::table object
    end

showing a visualization in a view
---------------------------------

you can invoke the rgviz method in your views. [read more about this](https://github.com/asterite/rgviz-rails/wiki/showing-a-visualization-in-a-view).

you can always do it the [old way](http://code.google.com/apis/visualization/documentation/using_overview.html).

executing queries over in-memory arrays
---------------------------------------

you can also apply a query over an array of arrays that contains your "records" to be queried.

    types = [[:id, :number], [:name, :string], [:age, :number]]
    records = [
      [1, 'john', 23],
      [2, 'pete', 36]
    ]
    executor = rgviz::memoryexecutor.new records, types

    render :rgviz => executor

this is very useful if you need to present visualizations against data coming from a csv file.

current limitations
-------------------

* the *format* clause works, but formatting is as in ruby (like "%.2f" for numbers, "foo %s bar" for strings, and "%y-%m-%d" for dates, as specified by time#strftime)
* only supports mysql, postgresql and sqlite adapters
* these scalar functions are not supported for sqlite: *millisecond*, *quarter*
* these scalar functions are not supported for mysql: *millisecond*
* the function *toDate* doesn't accept a number as its argument
* the *tsv* output format is not supported

contributors
------------

* [brad seefeld](https://github.com/bradseefeld)
