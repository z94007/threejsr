# THREEJS Geoms

#' Abstract Geom Type
#' @export
TGeom <- R6::R6Class(
  classname = 'TGeom',
  active = list(
    name = function(){
      private$mesh_name
    },
    type = function(){
      private$mesh_type
    }
  ),
  private = list(
    check_event_data = function(event_data, key_frames){
      if(missing(key_frames) && is.list(event_data)){
        key_frames = as.numeric(names(event_data))
      }
      if(any(duplicated(key_frames))){
        stop('key_frames MUST be distinct and numeric')
      }
      if(is.list(event_data)){
        names(event_data) = NULL
      }

      assertthat::assert_that(is.numeric(key_frames), msg = 'key_frames must be numeric matching the first dimension of event_data')
      n_frames = length(key_frames)
      if(is.array(event_data) && n_frames == dim(event_data)[1]){
        dim(event_data) = c(n_frames, prod(dim(event_data)[-1]))
      }else if(is.vector(event_data)){
        dim2 = length(event_data) / n_frames
        if(as.integer(dim2) != dim2){
          stop('event_data does not matches with key_frames')
        }
        dim(event_data) = c(n_frames, dim2)
      }else if(is.list(event_data) && n_frames == length(event_data)){
        # pass
      }else{
        stop('event_data does not matches with key_frames')
      }

      return(list(
        event_data = event_data,
        key_frames = sprintf('%.4f', as.numeric(key_frames))
      ))
    },

    mesh_name = '',
    geom_args = NULL,
    mesh_type = '',
    layer = 1,
    position = c(0,0,0),
    events = list(),
    transform = diag(1,4),
    controls = list(),
    # enabled_events = NULL,
    clippers = NULL,
    is_clipper = F,
    hover_enabled = T,
    clip_intersect = FALSE,
    hook_to = NULL
  ),
  public = list(
    mesh_info = '',
    user_data = list(),

    initialize = function(position, mesh_name, mesh_type, mesh_info = mesh_name, ...,
                          layer = 1, .args = list(),
                          hover_enabled = TRUE,
                          is_clipper = FALSE,
                          clippers = NULL, clip_intersect = F){
      private$position = position
      private$mesh_name = mesh_name
      private$mesh_type = mesh_type
      private$geom_args = c(list(...), .args)
      private$layer = layer
      # private$enabled_events = enabled
      self$mesh_info = mesh_info
      private$clippers = clippers
      private$hover_enabled = hover_enabled
      private$is_clipper = is_clipper
      private$clip_intersect = clip_intersect
    },

    extra_data = function(text = 'Click Here...', ...){
      self$user_data = c(list(text = text), list(...))
    },

    add_position_control = function( name, axis, label, min = 0, max = 1, initial = 0, step = 0.01, ..., index = NULL){
      self$add_numeric_control(
        type = 'Position',
        name = name,
        axis = axis,
        label = label,
        min = min,
        max = max,
        initial = initial,
        step = step,
        ...,
        index = index
      )
    },

    # Type is dat GUI folder name
    # label is this iterm name
    # l should be a list of initial, label, name, callback.... to match with dat GUI
    # index is the index of control, can avoid duplicated assignment
    add_custom_control = function( type = 'Custome', label, l, index = NULL){
      if(!is.list(private$controls[[type]])){
        private$controls[[type]] = list()
      }
      if(!missing(label)){
        l[['label']] = label
      }else{
        label = l[['label']]
      }
      l = list(l)
      names(l) = label

      if(is.null(index)){
        index = length(private$controls[[type]]) + 1
      }
      private$controls[[type]][index] = l
    },

    add_numeric_control = function( type = 'Custom', name, label, min = 0, max = 1, initial = 0, step = 0.01, ..., index = NULL){
      l = c(
        list(...),
        list(
          initial = initial,
          label = label,
          name = name,
          min = min,
          max = max,
          step = step
        )
      )
      self$add_custom_control(type = type, l = l, index = index )
    },

    add_visibility_control = function( type = 'Custom', name, label, initial = TRUE, ..., index = NULL){
      l = c(
        list(...),
        list(
          initial = initial,
          label = label,
          name = name,
          callback = 'function(value, mesh){mesh.visible=value;}'
        )
      )
      self$add_custom_control(type = type, l = l, index = index )
    },

    remove_event = function(event_type, name){
      if(!is.null(private$events[[event_type]])){
        for(ii in seq_along(private$events[[event_type]])){
          n = private$events[[event_type]][[ii]][['name']]
          if(length(n) && n == name){
            private$events[[event_type]][[ii]] = NULL
          }
        }
      }
    },

    add_event = function(event_type, name, event_data, key_frames, ...){
      re = private$check_event_data(event_data = event_data, key_frames = key_frames)

      if(is.null(private$events[[event_type]])){
        private$events[[event_type]] = list()
      }
      private$events[[event_type]][[length(private$events[[event_type]]) + 1]] = c(
        list(...),
        list(
          event_type = event_type,
          name = name,
          data = re$event_data,
          key_frames = re$key_frames
        )
      )
    },

    animation_event = function(name, event_data, key_frames, loop = FALSE, pixel_size = 3, alpha = FALSE, alpha_threshold = 0 ){
      self$add_event(
        event_type = 'animation',
        name = name,
        event_data = event_data,
        key_frames = key_frames,
        loop = loop,
        pixel_size = pixel_size,
        alpha = alpha,
        threshold = alpha_threshold
      )
    },

    positional_event = function(
      name,
      event_data,
      key_frames,
      axis = 'z',
      pixel_size = 3,
      alpha = FALSE,
      alpha_threshold = 0
    ) {
      self$add_event(
        event_type = 'position',
        name = name,
        event_data = event_data,
        key_frames = key_frames,
        axis = axis,
        pixel_size = pixel_size,
        alpha = alpha,
        threshold = alpha_threshold
      )
    },

    rotateX = function( theta ){
      c = cos(theta)
      s = sin(theta)

      x = matrix(c(
        1, 0, 0, 0,
        0, c, - s, 0,
        0, s, c, 0,
        0, 0, 0, 1
      ), byrow = T, nrow = 4)

      private$transform = x %*% private$transform
    },
    rotateY = function( theta ){
      c = cos(theta)
      s = sin(theta)

      x = matrix(c(
        c, 0, s, 0,
        0, 1, 0, 0,
        - s, 0, c, 0,
        0, 0, 0, 1
      ), byrow = T, nrow = 4)

      private$transform = x %*% private$transform
    },
    rotateZ = function( theta ){
      c = cos(theta)
      s = sin(theta)

      x = matrix(c(
        c, - s, 0, 0,
        s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
      ), byrow = T, nrow = 4)

      private$transform = x %*% private$transform
    },

    set_transform = function(mat, append = T){
      assertthat::assert_that(is.matrix(mat) && ncol(mat) == 4 && nrow(mat) == 4, msg = 'transform needs to be a 4x4 matrix.')
      if(append){
        mat = mat %*% private$transform
      }
      private$transform = mat
    },
    set_hook = function(hook_to){
      if(!missing(hook_to)){
        private$hook_to = hook_to
      }else{
        private$hook_to = NULL
      }
    },

    to_list = function(){
      list(
        mesh_type = private$mesh_type,
        mesh_name = private$mesh_name,
        geom_args = private$geom_args,
        position = private$position,
        layer = private$layer,
        events = private$events,
        controls = private$controls,
        transform = private$transform,
        mesh_info = self$mesh_info,
        clippers = private$clippers,
        hover_enabled = private$hover_enabled,
        is_clipper = private$is_clipper,
        clip_intersect = private$clip_intersect,
        extra_data = self$user_data,
        hook_to = private$hook_to
      )
    },
    to_json = function(){
      jsonlite::toJSON(self$to_list(), auto_unbox = T)
    }
  )
)



#' @export
as.list.TGeom <- function(obj){
  obj$to_list()
}
