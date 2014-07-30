define [
  'backbone'
  'underscore'
  'jquery'
  'cs!model/Steps'
  'cs!model/Step'
  'cs!view/StepView'
  'cs!view/ControlView'
  'cs!model/Hotspots'
  'cs!model/Hotspot'
  'cs!view/HotspotViewUser'
  'text!templates/app.html'
], (Backbone, _, $, Steps, Step, StepView, ControlView, Hotspots, Hotspot, HotspotView, Template)->
  class AppView extends Backbone.View

    template: _.template Template

    initialize:(args)->

      console.log args
      unless args.selector
        selector = "gallery-"+Date.now()
        $("body").append "<div id='"+selector+"'></div>"
        args.selector = selector
      @$el = $ '#'+args.selector
      @$el.append @template()
      console.log @$el

      @HotspotViews = []

      control = new Backbone.Model
      control.set
        total: args.config.steps.length
        current: 1
      controlView = new ControlView model: control
      controlView.on "changeStep", @changeSteps, @

      @$el.find(".gallery-container").append controlView.render().el
      @Steps = new Steps
      @listenTo @Steps, 'reset', @addAll
      @listenTo Hotspots, 'reset', @addAllHS
      @Steps.reset args.config.steps
      Hotspots.reset args.config.hotspots

    addAll: ->
      @stepView = new StepView collection: @Steps
      @$el.find('.steps').append @stepView.render().el

    addOneHS: (model)->
      stepModel = @Steps.first()
      view = new HotspotView model: model, currentStep: stepModel.get("_id")
      @HotspotViews.push view
      @$el.find('.hotspots').append view.render().el

    changeSteps:(stepnumber)->
      @stepView.change stepnumber
      for view in @HotspotViews
        id = @Steps.models[stepnumber-1].get("_id")
        view.changeCurrentStep(id)

    addAllHS: ->
      Hotspots.each @addOneHS, @

  for key, plugin of window.Pusch360Plugins
    $.get '/360images/'+plugin.dir+'/config.json', (cfg)->
      new AppView
        selector: plugin.selector
        config: cfg
