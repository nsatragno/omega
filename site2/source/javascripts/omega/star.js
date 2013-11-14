/* Omega Star JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Star = function(parameters){
  this.components        = [];
  this.shader_components = [];

  this.color             = 'FFFFFF';
  $.extend(this, parameters);

  this.color_int = parseInt('0x' + this.color);
};

Omega.Star.prototype = {
  json_class : 'Cosmos::Entities::Star',

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Star.gfx) === 'undefined'){
      Omega.Star.gfx = {};

      //// mesh
        // each star instance should override radius in the geometry instance
        var radius = 50, segments = 32, rings = 32;
        var mesh_geo = new THREE.SphereGeometry(radius, segments, rings);

        var lava_path      = config.url_prefix + config.images_path + config.resources.star.lava;
        var clouds_path    = config.url_prefix + config.images_path + config.resources.star.clouds;
        var lava_texture   = THREE.ImageUtils.loadTexture(lava_path, {}, event_cb);
        var clouds_texture = THREE.ImageUtils.loadTexture(clouds_path, {}, event_cb);

        // XXX
        var resolution =  new THREE.Vector2(window.innerWidth, window.innerHeight)

        var uniforms = {
          fogDensity: { type: "f",  value: 0.0001 },
          fogColor:   { type: "v3", value: new THREE.Vector3( 0, 0, 0 ) },
          time:       { type: "f",  value: 1.0 },
          resolution: { type: "v2", value: resolution },
          uvScale:    { type: "v2", value: new THREE.Vector2( 2.0, 1.5 ) },
          texture1:   { type: "t",  value: lava_texture },
          texture2:   { type: "t",  value: clouds_texture }
        };

        uniforms.texture1.value.wrapS = uniforms.texture1.value.wrapT = THREE.RepeatWrapping;
        uniforms.texture2.value.wrapS = uniforms.texture2.value.wrapT = THREE.RepeatWrapping;

        var vertex_shader   = Omega.get_shader('vertexShaderLava'  );
        var fragment_shader = Omega.get_shader('fragmentShaderLava');

        var material = new THREE.ShaderMaterial({
            uniforms       : uniforms,
            vertexShader   : vertex_shader,
            fragment_shader: fragment_shader});

// TODO migrate texture animation

        // each star instance should set position of their mesh instance
        Omega.Star.gfx.mesh = new THREE.Mesh(mesh_geo, material);

      //// glow
        var glow_geo    = mesh_geo.clone();

        vertex_shader   = Omega.get_shader('vertexShaderHalo');
        fragment_shader = Omega.get_shader('fragmentShaderHalo');
        uniforms        = {
          "c":   { type: "f", value: 0.2 },
          "p":   { type: "f", value: 4.0 },
        };

        material = new THREE.ShaderMaterial({
          uniforms       : uniforms,
          vertexShader   : vertex_shader,
          fragmentShader : fragment_shader,
          side           : THREE.BackSide
        });

        // each star instance should set position of their glow mesh instance
        Omega.Star.gfx.glow = new THREE.Mesh(glow_geo, material);

      //// light
        // each star instance should set the color/position of their light instance
        var color = '0xFFFFFF';
        Omega.Star.gfx.light = new THREE.PointLight(color, 1);
    }
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized

    this.load_gfx(config, event_cb);

    this.mesh  = Omega.Star.gfx.mesh.clone();
    this.mesh.position.set(this.location.x, this.location.y, this.location.z);
    //mesh.geometry // TODO how to adjust radius?

    this.shader_mesh = this.mesh.clone();

    this.glow  = Omega.Star.gfx.glow.clone();
    this.glow.position.set(this.location.x, this.location.y, this.location.z);

    this.light = Omega.Star.gfx.light.clone();
    this.light.position.set(this.location.x, this.location.y, this.location.z);
    this.light.color.setHex(this.color_int);

    this.components = [this.mesh, this.light];
    this.shader_components = [this.glow, this.shader_mesh];
  },
};
