A simple thread visualizer for Java thread dumps

# Requirements

* Ruby
* Graphviz

# Usage

    jstack -l <pid> | ruby stack.rb | dot -Tsvg > output.svg

Then, open the generated file with your favorite web browser.

# Examples

https://raw.githubusercontent.com/martint/stack/master/examples/contention.svg
https://raw.githubusercontent.com/martint/stack/master/examples/deadlock.svg
