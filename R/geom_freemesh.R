#' @export
GeomFreeMesh <- R6::R6Class(
  classname = 'FreeMesh',
  inherit = TGeom,

  private = list(
    vertices = NULL,
    faces = NULL,
    normals = NULL,
    colors = NULL
  ),

  public = list(
    initialize = function(
      position,
      mesh_name,
      mesh_info = mesh_name,
      vertices,
      faces,
      color = '#E6E6E6',
      ...
    ) {
      super$initialize(position = position, mesh_name = mesh_name,
                       mesh_info = mesh_info, mesh_type = 'freemesh', ...)

      private$vertices = as.vector(t(vertices[,1:3]))
      private$faces = as.vector(t(faces[,1:3]))
      private$normals = as.vector(replicate(nrow(vertices), c(0,0,1)))

      if(length(color) == 1){
        color = as.vector(col2rgb(color))
        color = color / 255
        color = as.vector(replicate(nrow(vertices), color))
      }else{
        assertthat::assert_that(length(color) == 3 * nrow(vertices),
                                msg = 'color MUST either be a length of one such as "#E2E2E2", or a rgb matrix with dimension 3x(# of vertices)')
        color = as.numeric(color)
      }

      private$colors = color

    },

    to_list = function(){
      re = super$to_list()
      re$geom_args = list(
        vertices = private$vertices,
        faces = private$faces,
        normals = private$normals,
        colors = private$colors
      )
      re
    }

  )
)
