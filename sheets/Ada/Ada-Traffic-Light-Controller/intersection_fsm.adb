package body Intersection_FSM is

   function Create return Intersection is
      I : Intersection;
   begin
      I.Signals   := [others => Red];
      I.Faulted   := False;
      I.Serving   := North_South;
      I.Has_Serve := False;
      return I;
   end Create;

   function Color_Of (I : Intersection; A : Axis) return Signal_Color is
   begin
      return I.Signals (A);
   end Color_Of;

   function Pedestrian_Of
     (I : Intersection; A : Axis) return Pedestrian_Indication
   is
   begin
      return Pedestrian_For (I.Signals (A));
   end Pedestrian_Of;

   function Is_Faulted (I : Intersection) return Boolean is
   begin
      return I.Faulted;
   end Is_Faulted;

   function In_All_Red (I : Intersection) return Boolean is
   begin
      return I.Signals (North_South) = Red
        and then I.Signals (East_West) = Red;
   end In_All_Red;

   function Active_Axis (I : Intersection) return Axis is
   begin
      return I.Serving;
   end Active_Axis;

   function Is_Safe (I : Intersection) return Boolean is
   begin
      return not Conflicts
        (I.Signals (North_South), I.Signals (East_West));
   end Is_Safe;

   procedure Grant_Green
     (I        : in out Intersection;
      For_Axis : Axis;
      Accepted : out Boolean)
   is
      Other : constant Axis :=
        (if For_Axis = North_South then East_West else North_South);
   begin
      if I.Faulted then
         Accepted := False;
         return;
      end if;

      --  Conflict: other axis still in Green or Yellow.
      if I.Signals (Other) = Green or else I.Signals (Other) = Yellow then
         Accepted := False;
         pragma Assert (Is_Safe (I));
         return;
      end if;

      --  Only grant from all-red clearance (or idle all-red).
      if not In_All_Red (I) then
         Accepted := False;
         return;
      end if;

      I.Signals (For_Axis) := Green;
      I.Signals (Other)    := Red;
      I.Serving            := For_Axis;
      I.Has_Serve          := True;
      Accepted             := True;
      pragma Assert (Is_Safe (I));
      pragma Assert (not Conflicts (I.Signals (North_South),
                                    I.Signals (East_West)));
   end Grant_Green;

   procedure Enter_Yellow
     (I        : in out Intersection;
      Accepted : out Boolean)
   is
   begin
      if I.Faulted or else not I.Has_Serve then
         Accepted := False;
         return;
      end if;

      if I.Signals (I.Serving) /= Green then
         Accepted := False;
         return;
      end if;

      I.Signals (I.Serving) := Yellow;
      Accepted := True;
      pragma Assert (Is_Safe (I));
   end Enter_Yellow;

   procedure Enter_All_Red
     (I        : in out Intersection;
      Accepted : out Boolean)
   is
   begin
      if I.Faulted then
         --  Already forced all-red by fault; treat as accepted no-op.
         I.Signals   := [others => Red];
         I.Has_Serve := False;
         Accepted    := True;
         return;
      end if;

      --  From Yellow (normal clearance) or already All_Red.
      if I.Has_Serve and then I.Signals (I.Serving) = Yellow then
         I.Signals   := [others => Red];
         I.Has_Serve := False;
         Accepted    := True;
      elsif In_All_Red (I) then
         Accepted := True;
      else
         Accepted := False;
      end if;
      pragma Assert (In_All_Red (I) or else not Accepted);
      pragma Assert (Is_Safe (I));
   end Enter_All_Red;

   procedure Raise_Fault (I : in out Intersection) is
   begin
      I.Faulted   := True;
      I.Signals   := [others => Red];
      I.Has_Serve := False;
      pragma Assert (In_All_Red (I));
      pragma Assert (Is_Safe (I));
   end Raise_Fault;

   procedure Clear_Fault (I : in out Intersection) is
   begin
      I.Faulted := False;
      I.Signals := [others => Red];
      I.Has_Serve := False;
   end Clear_Fault;

end Intersection_FSM;
