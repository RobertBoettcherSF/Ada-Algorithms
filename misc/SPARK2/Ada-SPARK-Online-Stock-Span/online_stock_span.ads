pragma Ada_2022;

package Online_Stock_Span with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Price is Natural range 0 .. 100;
   subtype Span is Natural range 0 .. 32;
   type Prices is array (Index) of Price;
   type Spans is array (Index) of Span;

   function All_Spans (P : Prices; Length : Length_Type) return Spans
     with Global => null;
end Online_Stock_Span;
