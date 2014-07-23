require [
  'backbone'
  'underscore'
  'jquery'
  'cs!/lib/model/Steps'
  'cs!/lib/model/Step'
  'cs!/lib/view/StepView'
  'cs!/lib/view/ControlView'
  'cs!/lib/model/Hotspots'
  'cs!/lib/model/Hotspot'
  'cs!/lib/view/HotspotView'
  'text!/lib/templates/app.html'
  'jquery.ui'
  'less!/main.less'
], (Backbone, _, $, Steps, Step, StepView, ControlView, Hotspots, Hotspot, HotspotView, Template)->
  class AppView extends Backbone.View
    events:
      "click #newHotspot": "newHotspot"
    newHotspot: ->
      that = @
      model = new Hotspot
      model.set
        title: $("#hotspot-title").val()
        content: $("#hotspot-content").val()
      @Hotspots.create model,
        success:->
          that.addOneHS model

    initialize:(args)->
      @StepViews = []
      @HotspotViews = []
      control = new Backbone.Model
      control.set
        total: args.config.steps.length
        current: 1
      controlView = new ControlView model: control
      controlView.on "changeStep", @changeSteps, @
      @el = $ args.selector
      @Steps = new Steps
      @Hotspots = new Hotspots
      @listenTo @Steps, 'reset', @addAll
      @listenTo @Hotspots, 'reset', @addAllHS
      @Steps.reset args.config.steps
      @Hotspots.reset args.config.hotspots
     
    addOne: (model)->
      if @StepViews.length is 0 then model.set "active", true
      view = new StepView model: model
      @StepViews.push view
      @el.append view.render().el

    addAll: ->
      @Steps.each @addOne, @

    addOneHS: (model)->
      stepModel = @Steps.first()
      view = new HotspotView model: model, currentStep: stepModel.get("_id")
      @HotspotViews.push view
      $('#hotspots').append view.render().el

    changeSteps:(step)->
      activeStep = @Steps.findActive()
      newStep = @Steps.findWhere _id: step
      newStep.set("active", true)
      activeStep?.set("active", false)

      for view in @HotspotViews
        view.changeCurrentStep(step)

    addAllHS: ->
      @Hotspots.each @addOneHS, @

  for key, plugin of window.Pusch360Plugins
    new AppView
      selector: plugin.selector
      config: plugin.config
