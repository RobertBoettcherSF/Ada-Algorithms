-- felics.adb
-- Implementation of the FELICS algorithm package.

package body Felics is

   --------------------
   -- Get_Neighbors --
   --------------------
   procedure Get_Neighbors
     (Image  : in Pixel_Matrix;
      Row    : in Positive;
      Col    : in Positive;
      P1     : out Pixel_Value;
      P2     : out Pixel_Value)
   is
      R_First : constant Positive := Image'First(1);
      C_First : constant Positive := Image'First(2);
   begin
      if Row < R_First or else Row > Image'Last(1) or else
         Col < C_First or else Col > Image'Last(2) then
         raise Invalid_Image_Dimensions;
      end if;

      -- Standard causal template: P1 is Left (Row, Col - 1), P2 is Above (Row - 1, Col)
      if Row = R_First and Col = C_First then
         -- Top-left corner: default reference value fallback
         P1 := 128;
         P2 := 128;
      elsif Row = R_First then
         -- Top row: only left neighbor exists
         P1 := Image(Row, Col - 1);
         P2 := Image(Row, Col - 1);
      elsif Col = C_First then
         -- Left column: only above neighbor exists
         P1 := Image(Row - 1, Col);
         P2 := Image(Row - 1, Col);
      else
         P1 := Image(Row, Col - 1);     -- Left
         P2 := Image(Row - 1, Col);     -- Above
      end if;
   end Get_Neighbors;

   ---------------------
   -- Compute_Context --
   ---------------------
   function Compute_Context
     (P1, P2 : in Pixel_Value) return Context_Record
   is
      L : Pixel_Value;
      H : Pixel_Value;
   begin
      if P1 < P2 then
         L := P1;
         H := P2;
      else
         L := P2;
         H := P1;
      end if;
      
      return (Lower => L, Higher => H, Delta_Value => Pixel_Value(Integer(H) - Integer(L)));
   end Compute_Context;

   ------------------
   -- Encode_Pixel --
   ------------------
   function Encode_Pixel
     (Pixel   : in Pixel_Value;
      Context : in Context_Record) return Encoded_Symbol
   is
      Val_Int : constant Integer := Integer(Pixel);
      L_Int   : constant Integer := Integer(Context.Lower);
      H_Int   : constant Integer := Integer(Context.Higher);
      Delta_I : constant Integer := Integer(Context.Delta_Value);
   begin
      if Val_Int >= L_Int and then Val_Int <= H_Int then
         -- Inside Range [L, H]
         return (Region => Inside_Range, Code => Val_Int - L_Int, Bits => Delta_I + 1);
      elsif Val_Int < L_Int then
         -- Below Range (< L)
         return (Region => Below_Range, Code => L_Int - Val_Int - 1, Bits => 8);
      else
         -- Above Range (> H)
         return (Region => Above_Range, Code => Val_Int - H_Int - 1, Bits => 8);
      end if;
   end Encode_Pixel;

   -------------------
   -- Decode_Symbol --
   -------------------
   function Decode_Symbol
     (Sym     : in Encoded_Symbol;
      Context : in Context_Record) return Pixel_Value
   is
      L_Int   : constant Integer := Integer(Context.Lower);
      H_Int   : constant Integer := Integer(Context.Higher);
   begin
      case Sym.Region is
         when Inside_Range =>
            declare
               Res : constant Integer := L_Int + Sym.Code;
            begin
               if Res < 0 or else Res > 255 then
                  raise Decoding_Error;
               end if;
               return Pixel_Value(Res);
            end;
         when Below_Range =>
            declare
               Res : constant Integer := L_Int - Sym.Code - 1;
            begin
               if Res < 0 or else Res > 255 then
                  raise Decoding_Error;
               end if;
               return Pixel_Value(Res);
            end;
         when Above_Range =>
            declare
               Res : constant Integer := H_Int + Sym.Code + 1;
            begin
               if Res < 0 or else Res > 255 then
                  raise Decoding_Error;
               end if;
               return Pixel_Value(Res);
            end;
      end case;
   end Decode_Symbol;

   --------------------
   -- Compress_Image --
   --------------------
   function Compress_Image
     (Image : in Pixel_Matrix) return Encoded_Stream
   is
      Rows : constant Integer := Image'Length(1);
      Cols : constant Integer := Image'Length(2);
      Total_Pixels : constant Positive := Positive(Rows * Cols);
      Stream : Encoded_Stream (1 .. Total_Pixels);
      Idx : Positive := 1;
   begin
      for R in Image'Range(1) loop
         for C in Image'Range(2) loop
            declare
               P1, P2 : Pixel_Value;
               Ctx    : Context_Record;
            begin
               Get_Neighbors(Image, R, C, P1, P2);
               Ctx := Compute_Context(P1, P2);
               Stream(Idx) := Encode_Pixel(Image(R, C), Ctx);
               Idx := Idx + 1;
            end;
         end loop;
      end loop;
      return Stream;
   end Compress_Image;

   ----------------------
   -- Decompress_Image --
   ----------------------
   function Decompress_Image
     (Stream : in Encoded_Stream;
      Rows   : in Positive;
      Cols   : in Positive) return Pixel_Matrix
   is
      Result_Image : Pixel_Matrix (1 .. Rows, 1 .. Cols);
      Idx : Positive := 1;
   begin
      if Stream'Length /= Rows * Cols then
         raise Invalid_Image_Dimensions;
      end if;

      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            declare
               P1, P2 : Pixel_Value;
               Ctx    : Context_Record;
            begin
               Get_Neighbors(Result_Image, R, C, P1, P2);
               Ctx := Compute_Context(P1, P2);
               Result_Image(R, C) := Decode_Symbol(Stream(Idx), Ctx);
               Idx := Idx + 1;
            end;
         end loop;
      end loop;
      return Result_Image;
   end Decompress_Image;

end Felics;
