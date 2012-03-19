require File.dirname(__FILE__) + '/../spec_helper'
#require 'rgviz'

include Rgviz

describe Executor do
  before :each do
    [Person, City, Country].each &:delete_all
  end

  def exec(query, options = {})
    exec = Executor.new options[:model] || Person
    exec.execute query, options
  end

  def format_datetime(date)
    date.strftime "new Date(%Y, %m, %d, %H, %M, %S)"
  end

  def format_date(date)
    date.strftime "new Date(%Y, %m, %d)"
  end

  def self.it_processes_single_select_column(query, id, type, value, label, format = nil, options = {}, test_options = {})
    it "processes select #{query}", test_options do
      if block_given?
        yield
      else
        Person.make
      end

      table = exec "select #{query}", options
      table.cols.length.should == 1

      table.cols[0].id.should == id
      table.cols[0].type.should == type
      table.cols[0].label.should == label

      table.rows.length.should == 1
      table.rows[0].c.length.should == 1

      table.rows[0].c[0].v.should == value
      table.rows[0].c[0].f.should == format
    end
  end

  it "processes select *" do
    p = Person.make

    table = exec 'select *'
    table.cols.length.should == 7

    i = 0
    [['id', :number], ['name', :string], ['age', :number], ['birthday', :date],
      ['created_at', :datetime], ['updated_at', :datetime],
      ['city_id', :number]].each do |id, type|
      table.cols[i].id.should == id
      table.cols[i].type.should == type
      table.cols[i].label.should == id
      i += 1
    end

    table.rows.length.should == 1
    table.rows[0].c.length.should == 7

    i = 0
    [p.id, p.name, p.age, p.birthday,
      p.created_at, p.updated_at, p.city.id].each do |val|
      table.rows[0].c[i].v.should == val
      i += 1
    end
  end

  it_processes_single_select_column 'name', 'name', :string, 'foo', 'name' do
    Person.make :name => 'foo'
  end

  it_processes_single_select_column '1', 'c0', :number, 1, '1'
  it_processes_single_select_column '1.2', 'c0', :number, 1.2, '1.2'
  it_processes_single_select_column '"hello"', 'c0', :string, 'hello', "'hello'"
  it_processes_single_select_column 'false', 'c0', :boolean, false, 'false'
  it_processes_single_select_column 'true', 'c0', :boolean, true, 'true'
  it_processes_single_select_column 'date "2010-01-02"', 'c0', :date, Time.parse('2010-01-02').to_date, "date '2010-01-02'"
  it_processes_single_select_column 'datetime "2010-01-02 10:11:12"', 'c0', :datetime, Time.parse('2010-01-02 10:11:12'), "datetime '2010-01-02 10:11:12'"
  it_processes_single_select_column 'timeofday "10:11:12"', 'c0', :timeofday, Time.parse('10:11:12'), "timeofday '10:11:12'"

  it_processes_single_select_column '1 + 2', 'c0', :number, 3, '1 + 2'
  it_processes_single_select_column '3 - 2', 'c0', :number, 1, '3 - 2'
  it_processes_single_select_column '2 * 3', 'c0', :number, 6, '2 * 3'
  it_processes_single_select_column '6 / 3', 'c0', :number, 2, '6 / 3'
  it_processes_single_select_column '3 * age', 'c0', :number, 60, '3 * age' do
    Person.make :age => 20
  end

  it_processes_single_select_column 'sum(age)', 'c0', :number, 6, 'sum(age)' do
    [1, 2, 3].each{|i| Person.make :age => i}
  end

  it_processes_single_select_column 'avg(age)', 'c0', :number, 30, 'avg(age)' do
    [10, 20, 60].each{|i| Person.make :age => i}
  end

  it_processes_single_select_column 'count(age)', 'c0', :number, 3, 'count(age)' do
    3.times{|i| Person.make}
  end

  it_processes_single_select_column 'max(age)', 'c0', :number, 3, 'max(age)' do
    [1, 2, 3].each{|i| Person.make :age => i}
  end

  it_processes_single_select_column 'min(age)', 'c0', :number, 1, 'min(age)' do
    [1, 2, 3].each{|i| Person.make :age => i}
  end

  it_processes_single_select_column 'age where age > 2', 'age', :number, 3, 'age' do
    [1, 2, 3].each{|i| Person.make :age => i}
  end

  it_processes_single_select_column 'age where age > 2 and age <= 3', 'age', :number, 3, 'age' do
    [1, 2, 3, 4, 5].each{|i| Person.make :age => i}
  end

  it_processes_single_select_column 'name where age is null', 'name', :string, 'b', 'name' do
    Person.make :age => 1, :name => 'a'
    Person.make :age => nil, :name => 'b'
  end

  it_processes_single_select_column "age where city_name = 'Laos' and year(birthday) = '2010'", 'age', :number, 1, 'age' do
    Person.make :age => 1, :name => 'a', :city => City.make(:name => 'Laos'), :birthday => '2010-01-01'
  end

  it_processes_single_select_column 'name where age is not null', 'name', :string, 'a', 'name' do
    Person.make :age => 1, :name => 'a'
    Person.make :age => nil, :name => 'b'
  end

  it "processes group by" do
    Person.make :name => 'one', :age => 1
    Person.make :name => 'one', :age => 2
    Person.make :name => 'two', :age => 3
    Person.make :name => 'two', :age => 4

    table = exec 'select max(age) group by name order by name'

    table.rows.length.should == 2
    table.rows[0].c.length.should == 1
    table.rows[0].c[0].v.should == 2
    table.rows[1].c.length.should == 1
    table.rows[1].c[0].v.should == 4
  end

  it "processes order by" do
    Person.make :age => 1
    Person.make :age => 3
    Person.make :age => 2

    table = exec 'select age order by age desc'

    table.rows.length.should == 3
    table.rows[0].c.length.should == 1
    table.rows[0].c[0].v.should == 3
    table.rows[1].c.length.should == 1
    table.rows[1].c[0].v.should == 2
    table.rows[2].c.length.should == 1
    table.rows[2].c[0].v.should == 1
  end

  it_processes_single_select_column 'age where age > 3 order by age limit 1', 'age', :number, 4, 'age' do
    [1, 2, 3, 4, 5].each{|i| Person.make :age => i}
  end

  it_processes_single_select_column 'age where age > 3 order by age limit 1 offset 1', 'age', :number, 5, 'age' do
    [1, 2, 3, 4, 5].each{|i| Person.make :age => i}
  end

  it_processes_single_select_column 'city_name', 'city_name', :string, 'Buenos Aires', 'city_name' do
    Person.make :city => City.make(:name => 'Buenos Aires')
  end

  it_processes_single_select_column 'city_country_name', 'city_country_name', :string, 'Argentina', 'city_country_name' do
    Person.make :city => City.make(:country => Country.make(:name => 'Argentina'))
  end

  it_processes_single_select_column 'city_country_name group by city_country_name', 'city_country_name', :string, 'Argentina', 'city_country_name' do
    Person.make :city => City.make(:country => Country.make(:name => 'Argentina'))
  end

  it "processes with conditions as string" do
    Person.make :age => 1
    Person.make :age => 2
    Person.make :age => 3

    table = exec 'select age', :conditions => 'age = 2'

    table.rows.length.should == 1
    table.rows[0].c.length.should == 1
    table.rows[0].c[0].v.should == 2
  end

  it "processes with conditions as string and another filter" do
    Person.make :age => 1
    Person.make :age => 2
    Person.make :age => 3

    table = exec 'select age where age > 1', :conditions => 'age < 3'

    table.rows.length.should == 1
    table.rows[0].c.length.should == 1
    table.rows[0].c[0].v.should == 2
  end

  it "processes with conditions as array" do
    Person.make :age => 1
    Person.make :age => 2
    Person.make :age => 3

    table = exec 'select age', :conditions => ['age = ?', 2]

    table.rows.length.should == 1
    table.rows[0].c.length.should == 1
    table.rows[0].c[0].v.should == 2
  end

  it "processes with conditions as array and another filter" do
    Person.make :age => 1
    Person.make :age => 2
    Person.make :age => 3

    table = exec 'select age where age > 1', :conditions => ['age < ?', 3]

    table.rows.length.should == 1
    table.rows[0].c.length.should == 1
    table.rows[0].c[0].v.should == 2
  end

  [['year', 2006], ['month', 5], ['day', 2],
   ['hour', 3], ['minute', 4], ['second', 9],
   ['dayOfWeek', 3]].each do |str, val|
    it_processes_single_select_column "#{str}(created_at)", 'c0', :number, val, "#{str}(created_at)" do
      Person.make :created_at => Time.parse('2006-05-02 3:04:09')
    end
  end

#  it_processes_single_select_column "quarter(created_at)", 'c0', :number, 2, 'quarter(created_at)' do
#    Person.make :created_at => Time.parse('2006-05-02 3:04:09')
#  end

  it_processes_single_select_column "dateDiff(date '2008-03-13', date '2008-03-10')", 'c0', :number, 3, "dateDiff(date '2008-03-13', date '2008-03-10')"

#  it_processes_single_select_column "now()", 'c0', :datetime, Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"), "now()" do
#    Person.make :created_at => Time.parse('2006-05-02 3:04:09')
#  end

  it_processes_single_select_column "toDate('2008-03-13')", 'c0', :date, Time.parse("2008-03-13").to_date, "toDate('2008-03-13')"

  it_processes_single_select_column "toDate(created_at)", 'c0', :date, Time.parse("2008-03-13").to_date, "toDate(created_at)" do
    Person.make :created_at => Time.parse('2008-03-13 3:04:09')
  end

#  it_processes_single_select_column "toDate(1234567890000)", 'c0', :date, Date.parse('2009-02-13').to_s, "toDate(1234567890000)"

  it_processes_single_select_column "upper(name)", 'c0', :string, 'FOO', "upper(name)" do
    Person.make :name => 'foo'
  end

  it_processes_single_select_column "lower(name)", 'c0', :string, 'foo', "lower(name)" do
    Person.make :name => 'FOO'
  end

  it_processes_single_select_column "concat(age)", 'c0', :string, '20', "concat(age)", nil, :extensions => true do
    Person.make :age => 20
  end

  it_processes_single_select_column "concat(name, 'bar')", 'c0', :string, 'foobar', "concat(name, 'bar')", nil, :extensions => true do
    Person.make :name => 'foo'
  end

  it_processes_single_select_column "name label name 'my name'", 'name', :string, 'foo', "my name" do
    Person.make :name => 'foo'
  end

  it_processes_single_select_column "1 + 2 label 1 + 2 'my name'", 'c0', :number, 3, "my name"

  it_processes_single_select_column "sum(age) label sum(age) 'my name'", 'c0', :number, 2, "my name" do
    Person.make :age => 2
  end

  it_processes_single_select_column "1 options no_values", 'c0', :number, nil, "1"

  it_processes_single_select_column '1 where foo_bars_id != 0', 'c0', :number, 1, '1', nil, :model => Foo do
    foo = Foo.create!
    FooBar.create! :foo_id => foo.id
  end

  it "processes pivot" do
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 1000
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 500
    Person.make :name => 'Eng', :birthday => '2000-01-13', :age => 600
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 400
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 350
    Person.make :name => 'Marketing', :birthday => '2000-01-13', :age => 800

    table = exec 'select name, sum(age) group by name pivot birthday order by name'

    table.cols.length.should == 3

    i = 0
    [['c0', :string, 'name'],
     ['c1', :number, '2000-01-12 sum(age)'],
     ['c2', :number, '2000-01-13 sum(age)']].each do |id, type, label|
      table.cols[i].id.should == id
      table.cols[i].type.should == type
      table.cols[i].label.should == label
      i += 1
    end

    table.rows.length.should == 3

    i = 0
    [['Eng', 1500, 600],
     ['Marketing', nil, 800],
     ['Sales', 750, nil]].each do |values|
      table.rows[i].c.length.should == 3
      values.each_with_index do |v, j|
        table.rows[i].c[j].v.should == v
      end
      i += 1
    end
  end

  it "processes pivot2" do
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 1000
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 500
    Person.make :name => 'Eng', :birthday => '2000-01-13', :age => 600
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 400
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 350
    Person.make :name => 'Marketing', :birthday => '2000-01-13', :age => 800

    table = exec 'select sum(age), name group by name pivot birthday order by name'

    table.cols.length.should == 3

    i = 0
    [['c0', :number, '2000-01-12 sum(age)'],
     ['c1', :number, '2000-01-13 sum(age)'],
     ['c2', :string, 'name']].each do |id, type, label|
      table.cols[i].id.should == id
      table.cols[i].type.should == type
      table.cols[i].label.should == label
      i += 1
    end

    table.rows.length.should == 3

    i = 0
    [[1500, 600, 'Eng'],
     [nil, 800, 'Marketing'],
     [750, nil, 'Sales']].each do |values|
      table.rows[i].c.length.should == 3
      values.each_with_index do |v, j|
        table.rows[i].c[j].v.should == v
      end
      i += 1
    end
  end

  it "processes pivot3" do
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 10
    Person.make :name => 'Eng', :birthday => '2001-02-12', :age => 10

    table = exec 'select name, sum(age) group by name pivot year(birthday), month(birthday)'

    table.cols.length.should == 3

    i = 0
    [['Eng', 10, 10]].each do |values|
      table.rows[i].c.length.should == 3
      values.each_with_index do |v, j|
        table.rows[i].c[j].v.should == v
      end
      i += 1
    end
  end

  it "processes pivot4" do
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 10
    Person.make :name => 'Sales', :birthday => '2001-02-12', :age => 20

    table = exec 'select birthday, month(birthday), sum(age) group by month(birthday) pivot name order by name'

    table.cols.length.should == 5

    i = 0
    [
      [Time.parse('2000-01-12').to_date, nil, 1, 10, nil],
      [nil, Time.parse('2001-02-12').to_date, 2, nil, 20],
    ].each do |values|
      table.rows[i].c.length.should == 5
      values.each_with_index do |v, j|
        table.rows[i].c[j].v.should == v
      end
      i += 1
    end
  end

  it "processes pivot without group by" do
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 1000
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 500
    Person.make :name => 'Eng', :birthday => '2000-01-13', :age => 600
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 400
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 350
    Person.make :name => 'Marketing', :birthday => '2000-01-13', :age => 800

    table = exec 'select sum(age) pivot name order by name'

    table.cols.length.should == 3

    i = 0
    [['c0', :number, 'Eng sum(age)'],
     ['c1', :number, 'Marketing sum(age)'],
     ['c2', :number, 'Sales sum(age)']].each do |id, type, label|
      table.cols[i].id.should == id
      table.cols[i].type.should == type
      table.cols[i].label.should == label
      i += 1
    end

    table.rows.length.should == 1

    i = 0
    [[2100, 800, 750]].each do |values|
      table.rows[i].c.length.should == 3
      values.each_with_index do |v, j|
        table.rows[i].c[j].v.should == v
      end
      i += 1
    end
  end

  it "processes pivot with no results" do
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 10
    Person.make :name => 'Sales', :birthday => '2001-02-12', :age => 20

    table = exec 'select birthday, sum(age) where 1 = 2 group by month(birthday) pivot name order by name'

    table.cols.length.should == 2

    i = 0
    [['birthday', :date, 'birthday'],
     ['c1', :number, 'sum(age)']].each do |id, type, label|
      table.cols[i].id.should == id
      table.cols[i].type.should == type
      table.cols[i].label.should == label
      i += 1
    end
  end

  it "processes pivot with group by not in select" do
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 10
    Person.make :name => 'Sales', :birthday => '2001-02-12', :age => 20

    table = exec 'select birthday, sum(age) group by month(birthday) pivot name order by name'

    table.cols.length.should == 4

    i = 0
    [
      [Time.parse('2000-01-12').to_date, nil, 10, nil],
      [nil, Time.parse('2001-02-12').to_date, nil, 20],
    ].each do |values|
      table.rows[i].c.length.should == 4
      values.each_with_index do |v, j|
        table.rows[i].c[j].v.should == v
      end
      i += 1
    end
  end

  it "processes pivot with zeros instead of nulls in count" do
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 1000
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 500
    Person.make :name => 'Eng', :birthday => '2000-01-13', :age => 600
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 400
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 350
    Person.make :name => 'Marketing', :birthday => '2000-01-13', :age => 800

    table = exec 'select name, count(age) group by name pivot birthday order by name'

    table.cols.length.should == 3

    i = 0
    [['c0', :string, 'name'],
     ['c1', :number, '2000-01-12 count(age)'],
     ['c2', :number, '2000-01-13 count(age)']].each do |id, type, label|
      table.cols[i].id.should == id
      table.cols[i].type.should == type
      table.cols[i].label.should == label
      i += 1
    end

    table.rows.length.should == 3

    i = 0
    [['Eng', 2, 1],
     ['Marketing', 0, 1],
     ['Sales', 2, 0]].each do |values|
      table.rows[i].c.length.should == 3
      values.each_with_index do |v, j|
        table.rows[i].c[j].v.should == v
      end
      i += 1
    end
  end

  # Formatting
  it_processes_single_select_column 'false format false "%s is falsey"', 'c0', :boolean, false, 'false', 'false is falsey'
  it_processes_single_select_column '1 format 1 "%.2f"', 'c0', :number, 1, '1', '1.00'
  it_processes_single_select_column '1.2 format 1.2 "%.2f"', 'c0', :number, 1.2, '1.2', '1.20'
  it_processes_single_select_column '"hello" format "hello" "%s world"', 'c0', :string, "hello", "'hello'", 'hello world'
  it_processes_single_select_column 'date "2001-01-02" format date "2001-01-02" "%Y"', 'c0', :date, Time.parse('2001-01-02').to_date, "date '2001-01-02'", '2001'

  it "processes pivot with format" do
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 1000
    Person.make :name => 'Eng', :birthday => '2000-01-12', :age => 500
    Person.make :name => 'Eng', :birthday => '2000-01-13', :age => 600
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 400
    Person.make :name => 'Sales', :birthday => '2000-01-12', :age => 350
    Person.make :name => 'Marketing', :birthday => '2000-01-13', :age => 800

    table = exec 'select name, sum(age) group by name pivot birthday order by name format name "x %s", sum(age) "%.2f"'

    table.cols.length.should == 3

    i = 0
    [['c0', :string, 'name'],
     ['c1', :number, '2000-01-12 sum(age)'],
     ['c2', :number, '2000-01-13 sum(age)']].each do |id, type, label|
      table.cols[i].id.should == id
      table.cols[i].type.should == type
      table.cols[i].label.should == label
      i += 1
    end

    table.rows.length.should == 3

    i = 0
    [[['Eng', 'x Eng'], [1500, '1500.00'], [600, '600.00']],
     [['Marketing', 'x Marketing'], [nil, nil], [800, '800.00']],
     [['Sales', 'x Sales'], [750, '750.00'], [nil, nil]]].each do |values|
      table.rows[i].c.length.should == 3
      values.each_with_index do |v, j|
        table.rows[i].c[j].v.should == v[0]
        table.rows[i].c[j].f.should == v[1]
      end
      i += 1
    end
  end

  it "raises on unknown column" do
    lambda { exec "select something" }.should raise_exception(Exception, "Unknown column something")
  end

  context "date formatting" do
    it "encodes date as json" do
      executor = Rgviz::Executor.new Person
      column = Rgviz::Column.new :type => :date
      value = executor.column_value column, "2012-01-02"
      value.encode_json.should eq("new Date(2012,0,02)")
    end

    it "encodes datetime as json" do
      executor = Rgviz::Executor.new Person
      column = Rgviz::Column.new :type => :datetime
      value = executor.column_value column, "2012-01-02 10:11:12"
      value.encode_json.should eq("new Date(2012,0,02,10,11,12)")
    end
  end
end
