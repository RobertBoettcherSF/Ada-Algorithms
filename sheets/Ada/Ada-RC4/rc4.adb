package body RC4
  with SPARK_Mode => On
is

   -- Helper to swap two bytes. Inlined for performance.
   procedure Swap (A, B : in out Byte)
     with Inline;

   procedure Swap (A, B : in out Byte) is
      Temp : constant Byte := A;
   begin
      A := B;
      B := Temp;
   end Swap;

   -- Advances the PRGA state (I and J) and swaps the corresponding state elements.
   -- This is the core state mutation shared by Next_Byte and Initialize_Drop.
   procedure Advance_State (Ctx : in out Context)
     with Inline;

   procedure Advance_State (Ctx : in out Context) is
   begin
      Ctx.I := Ctx.I + 1;
      Ctx.J := Ctx.J + Ctx.S (Ctx.I);
      Swap (Ctx.S (Ctx.I), Ctx.S (Ctx.J));
   end Advance_State;

   procedure Initialize (Ctx : out Context; Key : in Byte_Array) is
      J : Byte := 0;
   begin
      if Key'Length < 1 or else Key'Length > 256 then
         raise Invalid_Key_Length;
      end if;

      -- 1. Initialize S to identity permutation
      for I in Byte loop
         Ctx.S (I) := I;
      end loop;

      Ctx.I := 0;
      Ctx.J := 0;

      -- 2. Scramble S based on the Key
      for I in Byte loop
         declare
            -- Safe and zero-overhead modulo indexing, avoids index overflow
            Offset : constant Natural := Natural (I) mod Key'Length;
         begin
            J := J + Ctx.S (I) + Key (Key'First + Offset);
            Swap (Ctx.S (I), Ctx.S (J));
         end;
      end loop;
   end Initialize;

   procedure Initialize_Drop (Ctx : out Context; Key : in Byte_Array; Drop_Count : in Natural) is
   begin
      -- Standard KSA setup
      Initialize (Ctx, Key);
      
      -- Advance the state Drop_Count times without evaluating or keeping the output bytes
      for K in 1 .. Drop_Count loop
         Advance_State (Ctx);
      end loop;
   end Initialize_Drop;

   function Next_Byte (Ctx : in out Context) return Byte is
      T : Byte;
   begin
      Advance_State (Ctx);
      T := Ctx.S (Ctx.I) + Ctx.S (Ctx.J);
      return Ctx.S (T);
   end Next_Byte;

   function Process (Ctx : in out Context; Input : in Byte_Array) return Byte_Array is
      Output : Byte_Array (Input'Range);
   begin
      for K in Input'Range loop
         Output (K) := Input (K) xor Next_Byte (Ctx);
      end loop;
      return Output;
   end Process;

   procedure Process_In_Place (Ctx : in out Context; Data : in out Byte_Array) is
   begin
      for K in Data'Range loop
         Data (K) := Data (K) xor Next_Byte (Ctx);
      end loop;
   end Process_In_Place;

end RC4;
