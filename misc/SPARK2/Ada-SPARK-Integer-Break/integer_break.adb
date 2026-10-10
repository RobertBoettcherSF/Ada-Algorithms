pragma Ada_2022;
package body Integer_Break with SPARK_Mode => On is

   package LLI_Conversions is new Signed_Conversions (Int => Long_Long_Integer);
   function Big (V : Long_Long_Integer) return Big_Integer renames LLI_Conversions.To_Big_Integer;

   --  Row (M) for each M on its own, so that each proof sees one row.
   procedure Lemma_Row_2 with Ghost, Global => null, Post => Row (2);

   procedure Lemma_Row_2 is
   begin
      pragma Assert (Cand (2, 1) <= Best (2));
   end Lemma_Row_2;

   procedure Lemma_Row_3 with Ghost, Global => null, Post => Row (3);

   procedure Lemma_Row_3 is
   begin
      for K in 1 .. 2 loop
         pragma Assert (Cand (3, K) <= Best (3));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (3, K2) <= Best (3));
      end loop;
   end Lemma_Row_3;

   procedure Lemma_Row_4 with Ghost, Global => null, Post => Row (4);

   procedure Lemma_Row_4 is
   begin
      for K in 1 .. 3 loop
         pragma Assert (Cand (4, K) <= Best (4));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (4, K2) <= Best (4));
      end loop;
   end Lemma_Row_4;

   procedure Lemma_Row_5 with Ghost, Global => null, Post => Row (5);

   procedure Lemma_Row_5 is
   begin
      for K in 1 .. 4 loop
         pragma Assert (Cand (5, K) <= Best (5));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (5, K2) <= Best (5));
      end loop;
   end Lemma_Row_5;

   procedure Lemma_Row_6 with Ghost, Global => null, Post => Row (6);

   procedure Lemma_Row_6 is
   begin
      for K in 1 .. 5 loop
         pragma Assert (Cand (6, K) <= Best (6));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (6, K2) <= Best (6));
      end loop;
   end Lemma_Row_6;

   procedure Lemma_Row_7 with Ghost, Global => null, Post => Row (7);

   procedure Lemma_Row_7 is
   begin
      for K in 1 .. 6 loop
         pragma Assert (Cand (7, K) <= Best (7));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (7, K2) <= Best (7));
      end loop;
   end Lemma_Row_7;

   procedure Lemma_Row_8 with Ghost, Global => null, Post => Row (8);

   procedure Lemma_Row_8 is
   begin
      for K in 1 .. 7 loop
         pragma Assert (Cand (8, K) <= Best (8));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (8, K2) <= Best (8));
      end loop;
   end Lemma_Row_8;

   procedure Lemma_Row_9 with Ghost, Global => null, Post => Row (9);

   procedure Lemma_Row_9 is
   begin
      for K in 1 .. 8 loop
         pragma Assert (Cand (9, K) <= Best (9));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (9, K2) <= Best (9));
      end loop;
   end Lemma_Row_9;

   procedure Lemma_Row_10 with Ghost, Global => null, Post => Row (10);

   procedure Lemma_Row_10 is
   begin
      for K in 1 .. 9 loop
         pragma Assert (Cand (10, K) <= Best (10));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (10, K2) <= Best (10));
      end loop;
   end Lemma_Row_10;

   procedure Lemma_Row_11 with Ghost, Global => null, Post => Row (11);

   procedure Lemma_Row_11 is
   begin
      for K in 1 .. 10 loop
         pragma Assert (Cand (11, K) <= Best (11));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (11, K2) <= Best (11));
      end loop;
   end Lemma_Row_11;

   procedure Lemma_Row_12 with Ghost, Global => null, Post => Row (12);

   procedure Lemma_Row_12 is
   begin
      for K in 1 .. 11 loop
         pragma Assert (Cand (12, K) <= Best (12));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (12, K2) <= Best (12));
      end loop;
   end Lemma_Row_12;

   procedure Lemma_Row_13 with Ghost, Global => null, Post => Row (13);

   procedure Lemma_Row_13 is
   begin
      for K in 1 .. 12 loop
         pragma Assert (Cand (13, K) <= Best (13));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (13, K2) <= Best (13));
      end loop;
   end Lemma_Row_13;

   procedure Lemma_Row_14 with Ghost, Global => null, Post => Row (14);

   procedure Lemma_Row_14 is
   begin
      for K in 1 .. 13 loop
         pragma Assert (Cand (14, K) <= Best (14));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (14, K2) <= Best (14));
      end loop;
   end Lemma_Row_14;

   procedure Lemma_Row_15 with Ghost, Global => null, Post => Row (15);

   procedure Lemma_Row_15 is
   begin
      for K in 1 .. 14 loop
         pragma Assert (Cand (15, K) <= Best (15));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (15, K2) <= Best (15));
      end loop;
   end Lemma_Row_15;

   procedure Lemma_Row_16 with Ghost, Global => null, Post => Row (16);

   procedure Lemma_Row_16 is
   begin
      for K in 1 .. 15 loop
         pragma Assert (Cand (16, K) <= Best (16));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (16, K2) <= Best (16));
      end loop;
   end Lemma_Row_16;

   procedure Lemma_Row_17 with Ghost, Global => null, Post => Row (17);

   procedure Lemma_Row_17 is
   begin
      for K in 1 .. 16 loop
         pragma Assert (Cand (17, K) <= Best (17));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (17, K2) <= Best (17));
      end loop;
   end Lemma_Row_17;

   procedure Lemma_Row_18 with Ghost, Global => null, Post => Row (18);

   procedure Lemma_Row_18 is
   begin
      for K in 1 .. 17 loop
         pragma Assert (Cand (18, K) <= Best (18));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (18, K2) <= Best (18));
      end loop;
   end Lemma_Row_18;

   procedure Lemma_Row_19 with Ghost, Global => null, Post => Row (19);

   procedure Lemma_Row_19 is
   begin
      for K in 1 .. 18 loop
         pragma Assert (Cand (19, K) <= Best (19));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (19, K2) <= Best (19));
      end loop;
   end Lemma_Row_19;

   procedure Lemma_Row_20 with Ghost, Global => null, Post => Row (20);

   procedure Lemma_Row_20 is
   begin
      for K in 1 .. 19 loop
         pragma Assert (Cand (20, K) <= Best (20));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (20, K2) <= Best (20));
      end loop;
   end Lemma_Row_20;

   procedure Lemma_Row_21 with Ghost, Global => null, Post => Row (21);

   procedure Lemma_Row_21 is
   begin
      for K in 1 .. 20 loop
         pragma Assert (Cand (21, K) <= Best (21));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (21, K2) <= Best (21));
      end loop;
   end Lemma_Row_21;

   procedure Lemma_Row_22 with Ghost, Global => null, Post => Row (22);

   procedure Lemma_Row_22 is
   begin
      for K in 1 .. 21 loop
         pragma Assert (Cand (22, K) <= Best (22));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (22, K2) <= Best (22));
      end loop;
   end Lemma_Row_22;

   procedure Lemma_Row_23 with Ghost, Global => null, Post => Row (23);

   procedure Lemma_Row_23 is
   begin
      for K in 1 .. 22 loop
         pragma Assert (Cand (23, K) <= Best (23));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (23, K2) <= Best (23));
      end loop;
   end Lemma_Row_23;

   procedure Lemma_Row_24 with Ghost, Global => null, Post => Row (24);

   procedure Lemma_Row_24 is
   begin
      for K in 1 .. 23 loop
         pragma Assert (Cand (24, K) <= Best (24));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (24, K2) <= Best (24));
      end loop;
   end Lemma_Row_24;

   procedure Lemma_Row_25 with Ghost, Global => null, Post => Row (25);

   procedure Lemma_Row_25 is
   begin
      for K in 1 .. 24 loop
         pragma Assert (Cand (25, K) <= Best (25));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (25, K2) <= Best (25));
      end loop;
   end Lemma_Row_25;

   procedure Lemma_Row_26 with Ghost, Global => null, Post => Row (26);

   procedure Lemma_Row_26 is
   begin
      for K in 1 .. 25 loop
         pragma Assert (Cand (26, K) <= Best (26));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (26, K2) <= Best (26));
      end loop;
   end Lemma_Row_26;

   procedure Lemma_Row_27 with Ghost, Global => null, Post => Row (27);

   procedure Lemma_Row_27 is
   begin
      for K in 1 .. 26 loop
         pragma Assert (Cand (27, K) <= Best (27));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (27, K2) <= Best (27));
      end loop;
   end Lemma_Row_27;

   procedure Lemma_Row_28 with Ghost, Global => null, Post => Row (28);

   procedure Lemma_Row_28 is
   begin
      for K in 1 .. 27 loop
         pragma Assert (Cand (28, K) <= Best (28));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (28, K2) <= Best (28));
      end loop;
   end Lemma_Row_28;

   procedure Lemma_Row_29 with Ghost, Global => null, Post => Row (29);

   procedure Lemma_Row_29 is
   begin
      for K in 1 .. 28 loop
         pragma Assert (Cand (29, K) <= Best (29));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (29, K2) <= Best (29));
      end loop;
   end Lemma_Row_29;

   procedure Lemma_Row_30 with Ghost, Global => null, Post => Row (30);

   procedure Lemma_Row_30 is
   begin
      for K in 1 .. 29 loop
         pragma Assert (Cand (30, K) <= Best (30));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (30, K2) <= Best (30));
      end loop;
   end Lemma_Row_30;

   procedure Lemma_Row_31 with Ghost, Global => null, Post => Row (31);

   procedure Lemma_Row_31 is
   begin
      for K in 1 .. 30 loop
         pragma Assert (Cand (31, K) <= Best (31));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (31, K2) <= Best (31));
      end loop;
   end Lemma_Row_31;

   procedure Lemma_Row_32 with Ghost, Global => null, Post => Row (32);

   procedure Lemma_Row_32 is
   begin
      for K in 1 .. 31 loop
         pragma Assert (Cand (32, K) <= Best (32));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (32, K2) <= Best (32));
      end loop;
   end Lemma_Row_32;

   procedure Lemma_Row_33 with Ghost, Global => null, Post => Row (33);

   procedure Lemma_Row_33 is
   begin
      for K in 1 .. 32 loop
         pragma Assert (Cand (33, K) <= Best (33));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (33, K2) <= Best (33));
      end loop;
   end Lemma_Row_33;

   procedure Lemma_Row_34 with Ghost, Global => null, Post => Row (34);

   procedure Lemma_Row_34 is
   begin
      for K in 1 .. 33 loop
         pragma Assert (Cand (34, K) <= Best (34));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (34, K2) <= Best (34));
      end loop;
   end Lemma_Row_34;

   procedure Lemma_Row_35 with Ghost, Global => null, Post => Row (35);

   procedure Lemma_Row_35 is
   begin
      for K in 1 .. 34 loop
         pragma Assert (Cand (35, K) <= Best (35));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (35, K2) <= Best (35));
      end loop;
   end Lemma_Row_35;

   procedure Lemma_Row_36 with Ghost, Global => null, Post => Row (36);

   procedure Lemma_Row_36 is
   begin
      for K in 1 .. 35 loop
         pragma Assert (Cand (36, K) <= Best (36));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (36, K2) <= Best (36));
      end loop;
   end Lemma_Row_36;

   procedure Lemma_Row_37 with Ghost, Global => null, Post => Row (37);

   procedure Lemma_Row_37 is
   begin
      for K in 1 .. 36 loop
         pragma Assert (Cand (37, K) <= Best (37));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (37, K2) <= Best (37));
      end loop;
   end Lemma_Row_37;

   procedure Lemma_Row_38 with Ghost, Global => null, Post => Row (38);

   procedure Lemma_Row_38 is
   begin
      for K in 1 .. 37 loop
         pragma Assert (Cand (38, K) <= Best (38));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (38, K2) <= Best (38));
      end loop;
   end Lemma_Row_38;

   procedure Lemma_Row_39 with Ghost, Global => null, Post => Row (39);

   procedure Lemma_Row_39 is
   begin
      for K in 1 .. 38 loop
         pragma Assert (Cand (39, K) <= Best (39));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (39, K2) <= Best (39));
      end loop;
   end Lemma_Row_39;

   procedure Lemma_Row_40 with Ghost, Global => null, Post => Row (40);

   procedure Lemma_Row_40 is
   begin
      for K in 1 .. 39 loop
         pragma Assert (Cand (40, K) <= Best (40));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (40, K2) <= Best (40));
      end loop;
   end Lemma_Row_40;

   procedure Lemma_Row_41 with Ghost, Global => null, Post => Row (41);

   procedure Lemma_Row_41 is
   begin
      for K in 1 .. 40 loop
         pragma Assert (Cand (41, K) <= Best (41));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (41, K2) <= Best (41));
      end loop;
   end Lemma_Row_41;

   procedure Lemma_Row_42 with Ghost, Global => null, Post => Row (42);

   procedure Lemma_Row_42 is
   begin
      for K in 1 .. 41 loop
         pragma Assert (Cand (42, K) <= Best (42));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (42, K2) <= Best (42));
      end loop;
   end Lemma_Row_42;

   procedure Lemma_Row_43 with Ghost, Global => null, Post => Row (43);

   procedure Lemma_Row_43 is
   begin
      for K in 1 .. 42 loop
         pragma Assert (Cand (43, K) <= Best (43));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (43, K2) <= Best (43));
      end loop;
   end Lemma_Row_43;

   procedure Lemma_Row_44 with Ghost, Global => null, Post => Row (44);

   procedure Lemma_Row_44 is
   begin
      for K in 1 .. 43 loop
         pragma Assert (Cand (44, K) <= Best (44));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (44, K2) <= Best (44));
      end loop;
   end Lemma_Row_44;

   procedure Lemma_Row_45 with Ghost, Global => null, Post => Row (45);

   procedure Lemma_Row_45 is
   begin
      for K in 1 .. 44 loop
         pragma Assert (Cand (45, K) <= Best (45));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (45, K2) <= Best (45));
      end loop;
   end Lemma_Row_45;

   procedure Lemma_Row_46 with Ghost, Global => null, Post => Row (46);

   procedure Lemma_Row_46 is
   begin
      for K in 1 .. 45 loop
         pragma Assert (Cand (46, K) <= Best (46));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (46, K2) <= Best (46));
      end loop;
   end Lemma_Row_46;

   procedure Lemma_Row_47 with Ghost, Global => null, Post => Row (47);

   procedure Lemma_Row_47 is
   begin
      for K in 1 .. 46 loop
         pragma Assert (Cand (47, K) <= Best (47));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (47, K2) <= Best (47));
      end loop;
   end Lemma_Row_47;

   procedure Lemma_Row_48 with Ghost, Global => null, Post => Row (48);

   procedure Lemma_Row_48 is
   begin
      for K in 1 .. 47 loop
         pragma Assert (Cand (48, K) <= Best (48));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (48, K2) <= Best (48));
      end loop;
   end Lemma_Row_48;

   procedure Lemma_Row_49 with Ghost, Global => null, Post => Row (49);

   procedure Lemma_Row_49 is
   begin
      for K in 1 .. 48 loop
         pragma Assert (Cand (49, K) <= Best (49));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (49, K2) <= Best (49));
      end loop;
   end Lemma_Row_49;

   procedure Lemma_Row_50 with Ghost, Global => null, Post => Row (50);

   procedure Lemma_Row_50 is
   begin
      for K in 1 .. 49 loop
         pragma Assert (Cand (50, K) <= Best (50));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (50, K2) <= Best (50));
      end loop;
   end Lemma_Row_50;

   procedure Lemma_Row_51 with Ghost, Global => null, Post => Row (51);

   procedure Lemma_Row_51 is
   begin
      for K in 1 .. 50 loop
         pragma Assert (Cand (51, K) <= Best (51));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (51, K2) <= Best (51));
      end loop;
   end Lemma_Row_51;

   procedure Lemma_Row_52 with Ghost, Global => null, Post => Row (52);

   procedure Lemma_Row_52 is
   begin
      for K in 1 .. 51 loop
         pragma Assert (Cand (52, K) <= Best (52));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (52, K2) <= Best (52));
      end loop;
   end Lemma_Row_52;

   procedure Lemma_Row_53 with Ghost, Global => null, Post => Row (53);

   procedure Lemma_Row_53 is
   begin
      for K in 1 .. 52 loop
         pragma Assert (Cand (53, K) <= Best (53));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (53, K2) <= Best (53));
      end loop;
   end Lemma_Row_53;

   procedure Lemma_Row_54 with Ghost, Global => null, Post => Row (54);

   procedure Lemma_Row_54 is
   begin
      for K in 1 .. 53 loop
         pragma Assert (Cand (54, K) <= Best (54));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (54, K2) <= Best (54));
      end loop;
   end Lemma_Row_54;

   procedure Lemma_Row_55 with Ghost, Global => null, Post => Row (55);

   procedure Lemma_Row_55 is
   begin
      for K in 1 .. 54 loop
         pragma Assert (Cand (55, K) <= Best (55));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (55, K2) <= Best (55));
      end loop;
   end Lemma_Row_55;

   procedure Lemma_Row_56 with Ghost, Global => null, Post => Row (56);

   procedure Lemma_Row_56 is
   begin
      for K in 1 .. 55 loop
         pragma Assert (Cand (56, K) <= Best (56));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (56, K2) <= Best (56));
      end loop;
   end Lemma_Row_56;

   procedure Lemma_Row_57 with Ghost, Global => null, Post => Row (57);

   procedure Lemma_Row_57 is
   begin
      for K in 1 .. 56 loop
         pragma Assert (Cand (57, K) <= Best (57));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (57, K2) <= Best (57));
      end loop;
   end Lemma_Row_57;

   procedure Lemma_Row_58 with Ghost, Global => null, Post => Row (58);

   procedure Lemma_Row_58 is
   begin
      for K in 1 .. 57 loop
         pragma Assert (Cand (58, K) <= Best (58));
         pragma Loop_Invariant (for all K2 in 1 .. K => Cand (58, K2) <= Best (58));
      end loop;
   end Lemma_Row_58;

   procedure Lemma_Row (M : Number) is
   begin
      case M is
         when 2 =>
            Lemma_Row_2;
            pragma Assert (Row (M));
         when 3 =>
            Lemma_Row_3;
            pragma Assert (Row (M));
         when 4 =>
            Lemma_Row_4;
            pragma Assert (Row (M));
         when 5 =>
            Lemma_Row_5;
            pragma Assert (Row (M));
         when 6 =>
            Lemma_Row_6;
            pragma Assert (Row (M));
         when 7 =>
            Lemma_Row_7;
            pragma Assert (Row (M));
         when 8 =>
            Lemma_Row_8;
            pragma Assert (Row (M));
         when 9 =>
            Lemma_Row_9;
            pragma Assert (Row (M));
         when 10 =>
            Lemma_Row_10;
            pragma Assert (Row (M));
         when 11 =>
            Lemma_Row_11;
            pragma Assert (Row (M));
         when 12 =>
            Lemma_Row_12;
            pragma Assert (Row (M));
         when 13 =>
            Lemma_Row_13;
            pragma Assert (Row (M));
         when 14 =>
            Lemma_Row_14;
            pragma Assert (Row (M));
         when 15 =>
            Lemma_Row_15;
            pragma Assert (Row (M));
         when 16 =>
            Lemma_Row_16;
            pragma Assert (Row (M));
         when 17 =>
            Lemma_Row_17;
            pragma Assert (Row (M));
         when 18 =>
            Lemma_Row_18;
            pragma Assert (Row (M));
         when 19 =>
            Lemma_Row_19;
            pragma Assert (Row (M));
         when 20 =>
            Lemma_Row_20;
            pragma Assert (Row (M));
         when 21 =>
            Lemma_Row_21;
            pragma Assert (Row (M));
         when 22 =>
            Lemma_Row_22;
            pragma Assert (Row (M));
         when 23 =>
            Lemma_Row_23;
            pragma Assert (Row (M));
         when 24 =>
            Lemma_Row_24;
            pragma Assert (Row (M));
         when 25 =>
            Lemma_Row_25;
            pragma Assert (Row (M));
         when 26 =>
            Lemma_Row_26;
            pragma Assert (Row (M));
         when 27 =>
            Lemma_Row_27;
            pragma Assert (Row (M));
         when 28 =>
            Lemma_Row_28;
            pragma Assert (Row (M));
         when 29 =>
            Lemma_Row_29;
            pragma Assert (Row (M));
         when 30 =>
            Lemma_Row_30;
            pragma Assert (Row (M));
         when 31 =>
            Lemma_Row_31;
            pragma Assert (Row (M));
         when 32 =>
            Lemma_Row_32;
            pragma Assert (Row (M));
         when 33 =>
            Lemma_Row_33;
            pragma Assert (Row (M));
         when 34 =>
            Lemma_Row_34;
            pragma Assert (Row (M));
         when 35 =>
            Lemma_Row_35;
            pragma Assert (Row (M));
         when 36 =>
            Lemma_Row_36;
            pragma Assert (Row (M));
         when 37 =>
            Lemma_Row_37;
            pragma Assert (Row (M));
         when 38 =>
            Lemma_Row_38;
            pragma Assert (Row (M));
         when 39 =>
            Lemma_Row_39;
            pragma Assert (Row (M));
         when 40 =>
            Lemma_Row_40;
            pragma Assert (Row (M));
         when 41 =>
            Lemma_Row_41;
            pragma Assert (Row (M));
         when 42 =>
            Lemma_Row_42;
            pragma Assert (Row (M));
         when 43 =>
            Lemma_Row_43;
            pragma Assert (Row (M));
         when 44 =>
            Lemma_Row_44;
            pragma Assert (Row (M));
         when 45 =>
            Lemma_Row_45;
            pragma Assert (Row (M));
         when 46 =>
            Lemma_Row_46;
            pragma Assert (Row (M));
         when 47 =>
            Lemma_Row_47;
            pragma Assert (Row (M));
         when 48 =>
            Lemma_Row_48;
            pragma Assert (Row (M));
         when 49 =>
            Lemma_Row_49;
            pragma Assert (Row (M));
         when 50 =>
            Lemma_Row_50;
            pragma Assert (Row (M));
         when 51 =>
            Lemma_Row_51;
            pragma Assert (Row (M));
         when 52 =>
            Lemma_Row_52;
            pragma Assert (Row (M));
         when 53 =>
            Lemma_Row_53;
            pragma Assert (Row (M));
         when 54 =>
            Lemma_Row_54;
            pragma Assert (Row (M));
         when 55 =>
            Lemma_Row_55;
            pragma Assert (Row (M));
         when 56 =>
            Lemma_Row_56;
            pragma Assert (Row (M));
         when 57 =>
            Lemma_Row_57;
            pragma Assert (Row (M));
         when 58 =>
            Lemma_Row_58;
            pragma Assert (Row (M));
      end case;
   end Lemma_Row;

   type Value_Table is array (Part) of Value;
   type Part_Table is array (Part) of Part;

   --  B (M) = Best (M) for M <= N; C (M) is a best first part of M.
   type Solution is record
      B : Value_Table;
      C : Part_Table;
   end record;

   function Solve (N : Number) return Solution
   with
     Global => null,
     Post   => (for all M in 1 .. N => Solve'Result.B (M) = Best (M))
               and then (for all M in 2 .. N =>
                           Solve'Result.C (M) < M
                           and then Best (M) = Cand (M, Solve'Result.C (M)));

   function Solve (N : Number) return Solution is
      B : Value_Table := [others => 0];
      C : Part_Table := [others => 1];
   begin
      for M in 2 .. N loop
         pragma Loop_Invariant (for all M2 in 1 .. M - 1 => B (M2) = Best (M2));
         pragma Loop_Invariant
           (for all M2 in 2 .. M - 1 =>
              C (M2) < M2 and then Best (M2) = Cand (M2, C (M2)));
         Lemma_Row (M);
         declare
            Cur    : Value := 0;
            Choice : Part := 1;
         begin
            for K in 1 .. M - 1 loop
               pragma Loop_Invariant (Cur <= Best (M));
               pragma Loop_Invariant (if K > Arg (M) then Cur = Best (M));
               pragma Loop_Invariant
                 (Cur = 0 or else (Choice < K and then Cur = Cand (M, Choice)));
               declare
                  Rest : constant Long_Long_Integer := Long_Long_Integer'Max (Long_Long_Integer (M - K), B (M - K));
               begin
                  pragma Assert (Rest = Whole_Or_Split (M - K));
                  pragma Assert (Long_Long_Integer (K) * Rest = Cand (M, K));
                  pragma Assert (Cand (M, K) <= Best (M));
                  if Long_Long_Integer (K) * Rest > Cur then
                     Cur := Long_Long_Integer (K) * Rest;
                     Choice := K;
                  end if;
               end;
            end loop;
            pragma Assert (Cur = Best (M) and then Cur = Cand (M, Choice));
            B (M) := Cur;
            C (M) := Choice;
         end;
      end loop;
      return (B => B, C => C);
   end Solve;

   function Maximum (N : Number) return Positive is
      S : constant Solution := Solve (N);
   begin
      Lemma_Row (N);
      pragma Assert (Long_Long_Integer (1) * Whole_Or_Split (N - 1) <= Best (N));
      return Positive (S.B (N));
   end Maximum;

   --  Sum_To and Product_To of P (1 .. J) only read P (1 .. J). Body-only,
   --  for Best_Split's own arrays (origin 1 by declaration).
   procedure Lemma_Prefix_Frame (P1, P2 : Part_List; J : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => P1'First = 1 and then P2'First = 1 and then J <= P1'Last and then J <= P2'Last
                           and then (for all I in 1 .. J => P1 (I) = P2 (I)),
     Post               => Sum_To (P1, J) = Sum_To (P2, J) and then Product_To (P1, J) = Product_To (P2, J),
     Subprogram_Variant => (Decreases => J);

   procedure Lemma_Prefix_Frame (P1, P2 : Part_List; J : Natural) is
   begin
      if J > 0 then
         Lemma_Prefix_Frame (P1, P2, J - 1);
      end if;
   end Lemma_Prefix_Frame;

   --  One step of Sum_To / Product_To (the J-th part is P (P'First + J - 1)).
   procedure Lemma_Step (P : Part_List; J : Positive)
   with
     Ghost,
     Global => null,
     Pre    => J <= P'Length,
     Post   => Sum_To (P, J) = Sum_To (P, J - 1) + To_Big_Integer (P (P'First + (J - 1)))
               and then Product_To (P, J) = Product_To (P, J - 1) * To_Big_Integer (P (P'First + (J - 1)));
   procedure Lemma_Step (P : Part_List; J : Positive) is null;

   procedure Lemma_Mul_Mono (X, XX, Y : Big_Integer)
   with
     Ghost,
     Global => null,
     Pre    => 0 <= X and then X <= XX and then 0 <= Y,
     Post   => X * Y <= XX * Y;

   procedure Lemma_Mul_Mono (X, XX, Y : Big_Integer) is null;

   procedure Lemma_Assoc (X, Y, Z : Big_Integer)
   with
     Ghost,
     Global => null,
     Post   => (X * Y) * Z = X * (Y * Z);

   procedure Lemma_Assoc (X, Y, Z : Big_Integer) is null;

   procedure Lemma_Mul_Eq (X, XX, Y, YY : Big_Integer)
   with
     Ghost,
     Global => null,
     Pre    => X = XX and then Y = YY,
     Post   => X * Y = XX * YY;

   procedure Lemma_Mul_Eq (X, XX, Y, YY : Big_Integer) is null;

   --  The two conversions to Big_Integer agree.
   procedure Lemma_Conv (X : Natural)
   with
     Ghost,
     Global => null,
     Post   => Big (Long_Long_Integer (X)) = To_Big_Integer (X);

   procedure Lemma_Conv (X : Natural) is null;

   function Best_Split (N : Number) return Part_List is
      S     : constant Solution := Solve (N);
      B     : Value_Table renames S.B;
      C     : Part_Table renames S.C;
      R     : Part_List (1 .. N) := [others => 1];
      Count : Positive := 1;
      M     : Natural;
   begin
      R (1) := C (N);
      M := N - C (N);
      pragma Assert (Product_To (R, 1) * Big (Whole_Or_Split (M)) = Big (Best (N)));
      loop
         pragma Loop_Invariant (M >= 1 and then Count + M <= N);
         pragma Loop_Invariant (Sum_To (R, Count) = To_Big_Integer (N - M));
         pragma Loop_Invariant (Product_To (R, Count) * Big (Whole_Or_Split (M)) = Big (Best (N)));
         pragma Loop_Variant (Decreases => M);
         exit when Long_Long_Integer (M) >= B (M);
         declare
            Old_R : constant Part_List := R with Ghost;
            K     : constant Part := C (M);
            Old_P : constant Big_Integer := Product_To (R, Count) with Ghost;
         begin
            R (Count + 1) := K;
            Lemma_Prefix_Frame (R, Old_R, Count);
            Lemma_Step (R, Count + 1);
            pragma Assert (R'First + Count = Count + 1);
            pragma Assert (M >= 2 and then M <= N and then B (M) = Best (M));
            pragma Assert (Whole_Or_Split (M) = Best (M));
            pragma Assert (Best (M) = Cand (M, K));
            pragma Assert (Whole_Or_Split (M) = Long_Long_Integer (K) * Whole_Or_Split (M - K));
            pragma Assert (R (Count + 1) = K and then Product_To (R, Count) = Old_P);
            pragma Assert (Product_To (R, Count + 1) = Old_P * To_Big_Integer (K));
            Lemma_Conv (K);
            pragma Assert (Big (Whole_Or_Split (M)) = To_Big_Integer (K) * Big (Whole_Or_Split (M - K)));
            Lemma_Assoc (Old_P, To_Big_Integer (K), Big (Whole_Or_Split (M - K)));
            Lemma_Mul_Eq (Product_To (R, Count + 1), Old_P * To_Big_Integer (K),
                          Big (Whole_Or_Split (M - K)), Big (Whole_Or_Split (M - K)));
            pragma Assert (Product_To (R, Count + 1) * Big (Whole_Or_Split (M - K))
                           = Old_P * (To_Big_Integer (K) * Big (Whole_Or_Split (M - K))));
            pragma Assert (Product_To (R, Count + 1) * Big (Whole_Or_Split (M - K)) = Big (Best (N)));
            Count := Count + 1;
            M := M - K;
         end;
      end loop;
      declare
         Old_R : constant Part_List := R with Ghost;
         Old_P : constant Big_Integer := Product_To (R, Count) with Ghost;
      begin
         R (Count + 1) := M;
         Lemma_Prefix_Frame (R, Old_R, Count);
         Lemma_Step (R, Count + 1);
         pragma Assert (R'First + Count = Count + 1);
         pragma Assert (Whole_Or_Split (M) = Long_Long_Integer (M));
         pragma Assert (R (Count + 1) = M and then Product_To (R, Count) = Old_P);
         pragma Assert (Product_To (R, Count + 1) = Product_To (R, Count) * To_Big_Integer (R (Count + 1)));
         Lemma_Mul_Eq (Product_To (R, Count), Old_P, To_Big_Integer (R (Count + 1)), To_Big_Integer (M));
         pragma Assert (Product_To (R, Count + 1) = Old_P * To_Big_Integer (M));
         Lemma_Conv (M);
         pragma Assert (Product_To (R, Count + 1) = Big (Best (N)));
         Lemma_Conv (Maximum (N));
         pragma Assert (Product_To (R, Count + 1) = To_Big_Integer (Maximum (N)));
      end;
      declare
         Result : constant Part_List := R (1 .. Count + 1);
      begin
         Lemma_Prefix_Frame (Result, R, Count + 1);
         return Result;
      end;
   end Best_Split;

   --  P (1 .. J), summing to S <= Max_N, has product at most Whole_Or_Split (S).
   procedure Lemma_Opt_Prefix (P : Part_List; J : Positive)
   with
     Ghost,
     Global             => null,
     Pre                => J <= P'Length and then Sum_To (P, J) <= To_Big_Integer (Max_N),
     Post               => Product_To (P, J) <= Big (Whole_Or_Split (To_Integer (Sum_To (P, J)))),
     Subprogram_Variant => (Decreases => J);

   procedure Lemma_Opt_Prefix (P : Part_List; J : Positive) is
      S : constant Part := To_Integer (Sum_To (P, J)) with Ghost;
      X : constant Part := P (P'First + (J - 1)) with Ghost;   --  the J-th part
   begin
      if J > 1 then
         Lemma_Opt_Prefix (P, J - 1);
         declare
            S1 : constant Part := To_Integer (Sum_To (P, J - 1)) with Ghost;
         begin
            pragma Assert (S1 = S - X and then S >= 2 and then X < S);
            Lemma_Mul_Mono (Product_To (P, J - 1), Big (Whole_Or_Split (S1)), To_Big_Integer (X));
            Lemma_Row (S);
            pragma Assert (Cand (S, X) <= Best (S));
            pragma Assert (Long_Long_Integer (X) * Whole_Or_Split (S1) <= Whole_Or_Split (S));
            Lemma_Conv (X);
            pragma Assert (Big (Whole_Or_Split (S1)) * To_Big_Integer (X) <= Big (Whole_Or_Split (S)));
         end;
      end if;
   end Lemma_Opt_Prefix;

   procedure Lemma_Optimal (N : Number; P : Part_List) is
      J  : constant Positive := P'Length;
      X  : constant Part := P (P'First + (J - 1));   --  the last part
   begin
      Lemma_Opt_Prefix (P, J - 1);
      declare
         S1 : constant Part := To_Integer (Sum_To (P, J - 1));
      begin
         pragma Assert (S1 = N - X and then X < N);
         Lemma_Mul_Mono (Product_To (P, J - 1), Big (Whole_Or_Split (S1)), To_Big_Integer (X));
         Lemma_Row (N);
         pragma Assert (Cand (N, X) <= Best (N));
         pragma Assert (Long_Long_Integer (X) * Whole_Or_Split (S1) <= Best (N));
         Lemma_Conv (X);
         pragma Assert (Big (Whole_Or_Split (S1)) * To_Big_Integer (X) <= Big (Best (N)));
         Lemma_Conv (Maximum (N));
      end;
   end Lemma_Optimal;
end Integer_Break;
