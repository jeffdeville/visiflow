# Visiflow

Let's start with what Workflows are not.  They are not state machines.  A state machine allows your class to take certain actions based on it's internal state. But those changes are driven by external factors.  Any sequence of 'transitions' is incidental, and driven by whatever is controlling your class with the state machine.  

A workflow is very different.  It's just a sequence of steps that can branch. Intuitively, if you've ever creating a flowchart, you've created a workflow.  In fact, Visiflow will generate one based on your code automatically using GraphViz (such delicious irony)

So while you may have found this in ruby-toolbox under state machines, it isn't one. 

## Features

* Direct 1:1 mapping to simple workflows
* Generate workflow images using graphviz with rake
* Orthogonal extension points for logging, benchmarking, tracing, exception handling etc.
* Does not care what your persistence mechanism is.  (Of course, the downside is that you have to bring your own...)
* Easily extended to handle asynchronous jobs

## To Note Before You Start
This gem manages the sequence of steps in a workflow, but it does not concern itself with what those steps are, or what kind of object you bind it to. You can use it with Sidekiq, Resque, or DelayedJob, but you'll have to make sure you manage the 'state' of the workflow yourself.  See examples.

## Installation

Add this line to your application's Gemfile:

    gem 'visiflow'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install visiflow

## Usage

1. `include Driver` into whatever class you want to turn into a workflow
2. define a method called steps using the hash-based dsl (more on that later)
3. Understand that your workflow class instance will be the 'context' that shares data between the steps of your flow.  So define attr_accessors appropriately

### Optional
If you wish, for whatever reason, for your workflow to stop running for a certain period of time (waiting for an external event to come in, a 3rd party service is temporarily down, etc) implement persist_step, TODO: and whatever else might be necessary...  Perhaps a delay_until for delayed_job, resque, and sidekiq would be nice.

### Create Diagrams
`rake workflow:diagram` will generate workflow diagrams for every class that includes the Driver


## Contributing

1. Fork it ( http://github.com/<my-github-username>/visiflow/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
