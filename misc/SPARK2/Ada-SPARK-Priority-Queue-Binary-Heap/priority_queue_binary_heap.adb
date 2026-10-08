pragma Ada_2022;
package body Priority_Queue_Binary_Heap with SPARK_Mode => On is
   procedure Initialize (Q : out Queue) is begin for I in Index loop Q.Data (I) := 0; end loop; Q.Count := 0; end Initialize;
   function Size (Q : Queue) return Natural is begin return Q.Count; end Size;
   function Is_Empty (Q : Queue) return Boolean is begin return Q.Count = 0; end Is_Empty;
   procedure Insert (Q : in out Queue; Priority : Integer) is I : Index; P : Index; Temp : Integer;
   begin if Q.Count < Capacity then Q.Count := Q.Count + 1; I := Q.Count; Q.Data (I) := Priority; while I > 1 loop P := I / 2; exit when Q.Data (P) <= Q.Data (I); Temp := Q.Data (P); Q.Data (P) := Q.Data (I); Q.Data (I) := Temp; I := P; end loop; end if; end Insert;
   procedure Remove_Min (Q : in out Queue; Priority : out Integer) is I : Index; Left, Right, Small : Index; Temp : Integer;
   begin Priority := Q.Data (1); if Q.Count > 0 then Q.Data (1) := Q.Data (Q.Count); Q.Count := Q.Count - 1; I := 1; while I <= Q.Count / 2 loop Left := I * 2; Right := Left + 1; Small := Left; if Right <= Q.Count and then Q.Data (Right) < Q.Data (Left) then Small := Right; end if; exit when Q.Data (I) <= Q.Data (Small); Temp := Q.Data (I); Q.Data (I) := Q.Data (Small); Q.Data (Small) := Temp; I := Small; end loop; end if; end Remove_Min;
   function Minimum (Q : Queue) return Integer is begin return Q.Data (1); end Minimum;
end Priority_Queue_Binary_Heap;
