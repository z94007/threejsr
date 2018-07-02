/* Wrap up the whole script within a function
+(function(){

})();
*/


// Override methods so that we have multiple support across platforms
window.requestAnimationFrame =
    window.requestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.msRequestAnimationFrame ||
    window.oRequestAnimationFrame ||
    function (callback) {
        setTimeout(function() { callback(Date.now()); },  1000/60);
    };

function is_in(e, li){
  var re = false;
  if(e !== undefined){
    re = li.indexOf(e) > -1;
  }
  return(re);
}


HTMLWidgets.widget({

  name: "threejs_scene",

  type: "output",

  factory: function(el, width, height) {
    // get full width if not shiny mode
    if(!HTMLWidgets.shinyMode){
      // document.body.style.padding = 0;
      $('#htmlwidget_container').css({'margin':'-40px'});
      $(el).css({'height':'100vh'});
      window.dispatchEvent(new Event('resize'));
    }

    // Get DOM elements
    var $el = $(el),
        $side_pane = null,
        $info_pane = null,
        $ctrl_pane = null,
        $side_camr = null,
        eid = el.id,
        canvas = THREEJSRCANVAS.register(id = eid, el, width, height);

    // Add data gui
    var gui = new dat.GUI({ autoPlace: false }),
        gui_folders = {},
        gui_appended = false;

    window.cc = canvas;


    return {
      // "find", "renderError", "clearError", "sizing", "name", "type", "initialize", "renderValue", "resize"

      renderValue: function(x) {
        window.x = x;

        if(!HTMLWidgets.shinyMode){
          window.dispatchEvent(new Event('resize'));
        }
        canvas.clear_all();

        if($side_pane === null){
          $el.parent().prepend(x.sidebar);
          $side_pane = $el.siblings('.threejs-scene-aside'),
          $info_pane = $side_pane.find('.threejs-scene-info').last(),
          $ctrl_pane = $side_pane.find('.threejs-scene-control').last(),
          $side_camr = $side_pane.find('.threejs-scene-sidecamera').last(),
          // Set DOM elements
          $side_pane.height(height);

        }

        canvas.set_renderer_colors(
          new THREE.Color().fromArray(x.background_colors[0]),
          new THREE.Color().fromArray(x.background_colors[1])
        );


        x.geoms.forEach(function(e){
          e = JSON.parse(e);
          var mesh = canvas.add_mesh(
            e.mesh_type, e.mesh_name, e.geom_args,
            e.position, e.transform, e.layer,
            mesh_info = function(){
              $info_pane.html(e.mesh_info);
            },
            clippers = e.clippers,
            clip_intersect = e.clip_intersect,
            is_clipper = e.is_clipper,
            hover_enabled = e.hover_enabled
          );



          // Add control UIs
          Object.keys(e.controls).forEach(function(folder_name){
            var params = e.controls[folder_name];
            if(gui_folders[folder_name] === undefined){
              gui_folders[folder_name] = gui.addFolder(folder_name);
              gui_folders[folder_name].open();
            }

            // for each of params, i.e. p, add controls
            params.forEach(function(p){
              mesh.userData.__params[p.name] = p;
              p.__values = {};
              p.__values[p.label] = p.initial;

              if(typeof(p.callback) === 'string'){
                mesh.userData.__funs[p.name] = eval('var __tmp='+p.callback+';__tmp;');
                mesh.userData.__funs[p.name](p.initial, mesh);
              }

              gui_folders[folder_name].add(
                  p.__values, p.label, p.min, p.max
                ).step(p.step).onChange(function(value) {
                  if(typeof(mesh.userData.__funs[p.name]) === 'function'){
                    mesh.userData.__funs[p.name](value, mesh = mesh);
                  }
                });

            });

          });


          // add mesh event if exists
          // Add controls
          Object.keys(e.events).forEach(function(event_type){
            e.events[event_type].forEach(function(args){
              canvas.mesh_event(
                  mesh_name = e.mesh_name,
                  event_type = event_type,
                  args = args
                );
            });
          });


          if(x.control_gui && !gui_appended){
            gui_appended = true;
            $ctrl_pane.append(gui.domElement);
            $ctrl_pane.removeClass('hidden');
          }

        });

        canvas.switch_controls([x.control]);

        canvas.set_stats(x.show_stats);
        canvas.set_fps(x.fps);

        canvas.post_init();


        //--- Add sidebar cameras

        // Clear sidebar cameras
        $side_camr.html('');
        if(typeof(x.extra_cameras) === 'object' && x.extra_cameras !== null && (x.extra_cameras.length || 0) > 0){
          x.extra_cameras.forEach(function(args){
            canvas.side_camera(args.look_at, args);
          });

          canvas.set_side_renderer($side_camr[0]);
        }


      },

      resize: function(width, height) {
        if($side_pane !== null){
          $side_pane.height(height);
        }

        canvas.resize(width, height);
      },

      s: this
    };
  }
});