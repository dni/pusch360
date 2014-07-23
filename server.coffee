port = 6166
express = require "express"
ejs = require "ejs"
app = express()
async = require "async"
mongoose = require "mongoose"
Schema = mongoose.Schema
bodyParser = require('body-parser')

app.use bodyParser.urlencoded extended:true
app.use bodyParser.json()
app.use express.static __dirname

db = mongoose.connect 'mongodb://localhost/pusch360'
fs = require 'fs'

Gallery = mongoose.model 'galleries', new Schema
  dir : String
  steps: []
  hotspots: []
  date: Date

Step = mongoose.model 'steps', new Schema
  dir : String
  image: String
  hotspots: {}

Hotspot = mongoose.model 'hotspots', new Schema
  dir : String
  title : String
  content : String
  positions: Object

showGallery = (req, res)->
  dir = req.params.dir
  Gallery.find(dir: dir).exec (err, gallery)->
    return if gallery.length is 0
    gallery = gallery[0]
    Step.find(_id: $in: gallery.steps).exec (err, steps)->
      Hotspot.find(_id: $in: gallery.hotspots).exec (err, hotspots)->
        res.send ejs.render fs.readFileSync("./gallery.html", "utf8"),
          config:
            dir: gallery.dir
            steps: steps
            hotspots: hotspots

app.get "/show/:dir", showGallery

# root - overview
app.get "/", (req, res)->
  res.sendfile process.cwd()+'/index.html'


app.get "/show/:dir/steps", (req, res)->
  Step.find(dir: req.params.dir).exec (err, steps)->
    res.send steps

app.put "/show/:dir/steps/:id", (req, res)->
  Step.find(req.params.id).exec (err, steps)->
    console.log "updateSteps"
    res.send steps


#hotspot action!!
app.get "/show/:dir/hotspots", (req, res)->
  Hotspot.find(dir: req.params.dir).exec (err, hotspots)->
    res.send hotspots

app.post "/show/:dir/hotspots", (req, res)->
  dir = req.params.dir
  Gallery.find(dir: dir).exec (err, gallery)->
    return if gallery.length is 0
    gallery = gallery[0]
    hotspot = new Hotspot()
    hotspot.dir = req.params.dir
    hotspot.title = req.body.title
    hotspot.content = req.body.content
    hotspot.positions = req.body.positions
    hotspot.save ->
      gallery.hotspots.push hotspot._id
      gallery.save ->
        res.send hotspot


app.put "/show/:dir/hotspots/:id", (req, res)->
  Hotspot.findById(req.params.id).exec (err, hotspot)->
    hotspot.dir = req.params.dir
    hotspot.title = req.body.title
    hotspot.content = req.body.content
    hotspot.positions = req.body.positions
    hotspot.save ->
      res.send hotspot

app.delete "/show/:dir/hotspots/:id", (req, res)->
  Hotspots.findById(req.params.id).exec (err, hotspot)->
    res.send 'deleted'


# download
app.get "/download/:dir", (req, res)->
  Gallery.find(dir: req.params.dir).exec (err, gallery)->
    if err
      res.statusCode = 500
      res.end()
    spawn = require("child_process").spawn
    zip = spawn("zip", ["-r", "-", gallery.dir], cwd: "./360images/")
    res.contentType "zip"
    zip.stdout.on "data", (data) -> res.write data
    zip.on "exit", (code) ->
      if code isnt 0
        res.statusCode = 500
      res.end()

# init
app.get "/init/:dir", (req, res)->
  dir = req.params.dir
  gallery = new Gallery()
  Gallery.find(dir: dir).exec (err, galleryExists)->
    if galleryExists.length
      console.log galleryExists, "galleryExists"
      return res.send "already done init before, try /show/:dir forsowing and /reset/:dir for reseting"

    # save gallery after init
    doneStepping = (err)->
      gallery.save ->
        res.send "done init, try /show/:dir"

    # create new steps for each jpg
    stepping = (file, callback)->
      if file.match(/.jpg/g)
        step = new Step()
        step.dir = dir
        step.image = file
        step.save ->
          gallery.steps.push step._id
          callback()
      else
        callback()

    # new gallery
    gallery.dir = dir
    gallery.date = new Date()
    console.log 'creating new gallery: '+gallery.dir

    dirName = '360images/'+dir+'/'
    fs.readdir dirName, (err, files) ->
      return if err
      async.each files, stepping, doneStepping

# reset
app.get "/reset/:dir", (req, res)->
  dir = req.params.dir
  Gallery.find(dir: dir).exec (err, gallery)->
    return res.send "gallery doesnt exists" if gallery.length is 0
    gallery = gallery[0]
    Step.find(_id: $in: gallery.steps).exec (err, steps)->
      for step in steps
        step.remove()
    Hotspot.find(_id: $in: gallery.hotspots).exec (err, hotspots)->
       for spot in hotspots
        spot.remove()
    gallery.remove()
    res.send("gallery reseted, ready to init again")

app.listen port
console.log "Welcome to Pusch360! server runs on port "+port
