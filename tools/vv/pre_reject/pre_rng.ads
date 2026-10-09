--  Seeded generator for the Pre-rejection drivers (tools/vv/pre_reject).
package Pre_Rng is
   Sample : constant := 10_000;
   Seed   : constant := 20_261_009;
   procedure Reset;
   function Draw (Lo, Hi : Long_Long_Integer) return Long_Long_Integer;
   --  Uniform in Lo .. Hi (SplitMix64, reduced mod the span).
   function Draw (Lo, Hi : Integer) return Integer;
   procedure Report (Folder, Subprogram, Generator : String; Rejected : Natural);
   --  One line: folder|subprogram|generator|sample|rejected
end Pre_Rng;
