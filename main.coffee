React = require 'react'
YAML = require 'js-yaml'
prettyaml = require 'prettyaml'

{button, div, textarea, pre} = React.DOM

Main = React.createClass
  getInitialState: ->
    params: prettyaml.stringify({
      reduceFn: '_sum'
      reduce: true
      group: true
      group_level: 1
    })
    display: null

  defaultEmitted: '2014, "blue" : 1\n2014, "red": 2\n2014, "blue" :3\n2015, "yellow": 2.3\n2014, "red": 0\n2015, "red": -1'

  componentWillMount: ->
    if location.hash
      try
        state = JSON.parse location.hash.slice 1
        @defaultEmitted = state.emitted
        @state.params = state.params
      catch e

  componentDidMount: ->
    @recalc()

  render: ->
    (div {},
      (div className: 'third',
        (textarea
          ref: 'emitted'
          onBlur: @recalc
          defaultValue: @defaultEmitted
        )
      )
      (div className: 'third',
        (textarea
          value: @state.params
          onChange: @changeParams
          onBlur: @recalc
        )
        (button
          onClick: @save
        , 'Save to URL')
      )
      (div className: 'third',
        (pre {},
          @state.display if @state.display
        )
      )
    )

  pouch:
    destroy: (cb) -> cb()

  save: (e) ->
    e.preventDefault()
    location.hash = JSON.stringify({
      params: @state.params
      emitted: @refs.emitted.getDOMNode().value
    })

  changeParams: (e) ->
    @setState params: e.target.value

  recalc: (e) ->
    emitted = @refs.emitted.getDOMNode().value.split('\n')
    docs = []

    for row in emitted
      splittedRow = row.split(':')
      key = splittedRow[0].trim()
      try
        value = splittedRow[1].trim()
      catch e
        value = null

      try
        parsedKey = YAML.load "[#{key}]"
      catch e
        try
          parsedKey = YAML.load key
        catch e
          parsedKey = YAML.load key

      docs.push {
        key: parsedKey
        value: YAML.load value
      }

    params = YAML.load(@state.params) or {}
    reduce = params.reduceFn or null
    delete params.reduce

    @pouch.destroy =>
      @pouch = new PouchDB Math.random().toString(), {adapter: 'memory'}
      @pouch.bulkDocs docs, =>

        ddoc = {
          _id: '_design/simulate'
          views:
            simulate:
              map: 'function (doc) { emit(doc.key, doc.value) }'
        }
        if reduce
          ddoc.views.simulate.reduce = reduce

        @pouch.put ddoc, =>
          @pouch.query 'simulate', params, (err, res) =>
            formatted = []
            for row in res.rows
              if row.id
                delete row.id
              formatted.push JSON.stringify(row)
            formatted = formatted.join('\n')
            @setState display: formatted
      
React.renderComponent Main(), document.getElementById('main')
