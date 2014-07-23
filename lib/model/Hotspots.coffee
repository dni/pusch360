define [
  'backbone'
  'underscore'
  'cs!/lib/model/Hotspot'
], (Backbone, _, Hotspot)->

  class Hotspots extends Backbone.Collection
    url: window.location.pathname+"/hotspots"
    model: Hotspot
