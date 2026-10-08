package R is
   type T is private;
   function Get (G : T) return Natural;
   procedure Step (G : in out T)
     with Post => (if Get (G) = 5 then True else Get (G) = Get (G'Old) + 1);
private
   type T is record
      V : Natural := 5;
   end record;
   function Get (G : T) return Natural is (G.V);
end R;
