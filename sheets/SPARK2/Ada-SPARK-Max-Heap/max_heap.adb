pragma Ada_2022;
package body Max_Heap with SPARK_Mode => On is
   procedure Initialize (H : out Heap) is
   begin
      H.Data := (others => 0); H.Length := 0;
   end Initialize;
   function Empty (H : Heap) return Boolean is (H.Length = 0);
   procedure Push (H : in out Heap; Value : Integer; Added : out Boolean) is
      Pos, Parent : Position; Temp : Integer;
   begin
      Added := False;
      if H.Length < Capacity then
         H.Length := H.Length + 1;
         Pos := Position (H.Length);
         H.Data (Pos) := Value;
         for Step in Position loop
            exit when Pos = 1;
            Parent := Pos / 2;
            exit when H.Data (Parent) >= H.Data (Pos);
            Temp := H.Data (Parent); H.Data (Parent) := H.Data (Pos); H.Data (Pos) := Temp;
            Pos := Parent;
         end loop;
         Added := True;
      end if;
   end Push;
   procedure Pop (H : in out Heap; Value : out Integer; Removed : out Boolean) is
      Pos, Left, Right, Small, Last : Position; Temp : Integer;
   begin
      Value := 0; Removed := False;
      if H.Length > 0 then
         Value := H.Data (1);
         Last := Position (H.Length);
         if H.Length = 1 then
            H.Length := 0;
         else
            H.Data (1) := H.Data (Last); H.Length := H.Length - 1; Pos := 1;
            for Step in Position loop
               exit when Pos > H.Length / 2;
               Left := Pos * 2; Right := Left;
               if Right < H.Length then Right := Right + 1; end if;
               Small := Left;
               if H.Data (Right) > H.Data (Left) then Small := Right; end if;
               exit when H.Data (Small) >= H.Data (Pos);
               Temp := H.Data (Small); H.Data (Small) := H.Data (Pos); H.Data (Pos) := Temp; Pos := Small;
            end loop;
         end if;
         Removed := True;
      end if;
   end Pop;
end Max_Heap;
