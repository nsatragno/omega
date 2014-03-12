pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  describe("callbacks", function(){
    describe("#defended_stop", function(){
      var page, tracker;
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
        sinon.stub(page.canvas, 'reload');

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tracker = new Omega.UI.CommandTracker({page : page});

        tgt    = Omega.Gen.ship({id : 'target_ship', system_id : 'system1' });
        etgt   = Omega.Gen.ship({id : 'target_ship', hp : 77, shield_level : 99 });
        ship   = Omega.Gen.ship({id: 'ship1'});
        eship  = Omega.Gen.ship({id: 'ship1', attacking : etgt});

        page.entities = [ship, tgt];
        page.canvas.entities = [tgt.id];
        eargs         = ['defended_stop', etgt, eship];
      });

      after(function(){
        page.canvas.reload.restore();
      });

      it("updates entity hp and shield level", function(){
        tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
        assert(tgt.hp).equals(77);
        assert(tgt.shield_level).equals(99);
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          tgt.parent_id = 'system2';
          tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(page.canvas.reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(page.canvas.reload, tgt, sinon.match.func);
      });

      it("updates entity gfx", function(){
        sinon.stub(tgt, 'update_gfx');
        tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
        page.canvas.reload.omega_callback()();
        sinon.assert.called(tgt.update_gfx);
      });
    });
  });
});});