pragma Ada_2022;
package body Ring_Buffer with SPARK_Mode => On is
   procedure Initialize (B : out Buffer) is
   begin
      for I in Index loop B.Data (I) := 0; end loop;
      B.Head := Index'First; B.Tail := Index'First; B.Count := 0;
   end Initialize;
   function Is_Empty (B : Buffer) return Boolean is begin return B.Count = 0; end Is_Empty;
   function Is_Full (B : Buffer) return Boolean is begin return B.Count = Capacity; end Is_Full;
   function Length (B : Buffer) return Natural is begin return B.Count; end Length;
   procedure Append (B : in out Buffer; Value : Integer) is
   begin
      B.Data (B.Tail) := Value;
      if B.Tail = Index'Last then B.Tail := Index'First; else B.Tail := B.Tail + 1; end if;
      if B.Count < Capacity then B.Count := B.Count + 1; end if;
   end Append;
   procedure Remove (B : in out Buffer; Value : out Integer) is
   begin
      Value := B.Data (B.Head);
      if B.Head = Index'Last then B.Head := Index'First; else B.Head := B.Head + 1; end if;
      if B.Count > 0 then B.Count := B.Count - 1; end if;
   end Remove;
   function Front (B : Buffer) return Integer is begin return B.Data (B.Head); end Front;
end Ring_Buffer;
