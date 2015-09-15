class HtmlBrunchStatic
  constructor: (config) ->
    @processors = config?.processors or []
    @defaultContext = config?.defaultContext
    @partials = config?.partials or /partials?/
    @layouts = config?.layouts or /layouts?/
    @handlebarsOptions = config?.handlebars
    if @handlebarsOptions?.enableProcessor
      @processors.push new HandlebarsBrunchStatic @handlebarsOptions.enableProcessor
      delete @handlebarsOptions.enableProcessor

  handles: (filename) ->
    @getProcessor(filename) isnt null

  getProcessor: (filename) ->
    map = (p) ->
      if p.handles.constructor is Function
        (f) -> p.handles f
      else
        p.handles
    processorIdx = anymatch @processors.map(map), filename, true
    if processorIdx is -1 then null else @processors[processorIdx]

  transformPath: (filename) ->
    processor = @getProcessor filename
    return filename unless processor
    if processor.transformPath
      processor.transformPath filename
    else
      filename.replace(new RegExp(path.extname(filename) + '$'), '.html')

  compile: (data, filename, callback) ->
    if anymatch(@partials, filename) or anymatch(@layouts, filename)
      # don't output partials and layouts
      do callback
      return

    loader = new TemplateLoader
    template = loader.load filename, data, @defaultContext
    if template instanceof Error
      callback template
      return
    template.compile @, (err, content) =>
      if err
        callback err
        return

      result =
        filename: @transformPath filename
        content: content
      callback null, [result], template.dependencies

module.exports = (config) -> new HtmlBrunchStatic config

