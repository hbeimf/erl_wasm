-module(wasm_lib).
-export([encode/1]).

-import(eleb128, [ signed_encode/1, unsigned_encode/1 ]).

encode({module, _Sections} = Module) ->
  do_encode(Module).

%% Module
do_encode({module, Sections}) ->
  EncodedContents = do_encode_sequence(Sections),
  <<"\0asm", 1, 0, 0, 0, EncodedContents/binary>>;

%% Sections
do_encode({type_sec, Contents}) -> do_encode_section(1, {vec, Contents});
do_encode({import_sec, Contents}) -> do_encode_section(2, {vec, Contents});
do_encode({func_sec, Contents}) -> do_encode_section(3, {vec, Contents});
do_encode({table_sec, Contents}) -> do_encode_section(4, {vec, Contents});
do_encode({mem_sec, Contents}) -> do_encode_section(5, {vec, Contents});
do_encode({global_sec, Contents}) -> do_encode_section(6, {vec, Contents});
do_encode({export_sec, Contents}) -> do_encode_section(7, {vec, Contents});
do_encode({elem_sec, Contents}) -> do_encode_section(9, {vec, Contents});
do_encode({code_sec, Contents}) -> do_encode_section(10, {vec, Contents});
do_encode({data_sec, Contents}) -> do_encode_section(11, {vec, Contents});
do_encode({custom_sec, Contents}) -> do_encode_section(0, Contents);
do_encode({start_sec, Contents}) -> do_encode_section(8, Contents);

%% Value types
do_encode({val_type, i32}) -> <<16#7F>>;
do_encode({val_type, i64}) -> <<16#FE>>;
do_encode({val_type, f32}) -> <<16#7D>>;
do_encode({val_type, f64}) -> <<16#7C>>;

%% Result types
do_encode({block_type, []}) -> <<16#40>>;
do_encode({block_type, Types}) -> do_encode_sequence(Types);

%% Function types
do_encode({func_type, ParamTypes, ResultTypes}) ->
  do_encode_instr2(16#60, {vec, ParamTypes}, {vec, ResultTypes});

%% Memory types
do_encode({mem_type, Limit}) -> do_encode(Limit);
do_encode({limits, Min}) -> do_encode_instr1(16#00, {u32, Min});
do_encode({limits, Min, Max}) -> do_encode_instr2(16#01, {u32, Min}, {u32, Max});

%% Table types
do_encode({table_type, ElemType, Limit}) ->
  EncodedElemType = do_encode(ElemType),
  EncodedLimit = do_encode(Limit),
  <<EncodedElemType/binary, EncodedLimit/binary>>;
do_encode(elem_type) -> <<16#70>>;

%% Global types
do_encode({global_type, const, ValType}) ->
  EncodedValType = do_encode(ValType),
  <<16#00, EncodedValType/binary>>;
do_encode({global_type, var, ValType}) ->
  EncodedValType = do_encode(ValType),
  <<16#01, EncodedValType/binary>>;

%% Parametric instructions
do_encode(drop) -> <<16#A1>>;
do_encode(select) -> <<16#1B>>;

%% Control instructions
do_encode(return) -> <<16#0F>>;
do_encode(unreachable) -> <<16#00>>;
do_encode(nop) -> <<16#01>>;
do_encode({loop, ResultType, Body}) ->
  do_encode_instr2(16#03, ResultType, Body);
do_encode({if_no_else, ResultType, Body}) ->
  EncodedFront = do_encode_instr2(16#04, ResultType, Body),
  <<EncodedFront/binary, 16#0B>>;
do_encode({if_else, ResultType, Consequent, Alternate}) ->
  EncodedFront = do_encode_instr2(16#04, ResultType, Consequent),
  EncodedAlternate = do_encode_sequence(Alternate),
  <<EncodedFront/binary, 16#05, EncodedAlternate/binary, 16#0B>>;
do_encode({br_table, LabelIndices, LabelIdx}) ->
  do_encode_instr2(16#0D, LabelIndices, LabelIdx);
do_encode({br, LabelIdx}) ->
  do_encode_instr1(16#05, LabelIdx);
do_encode({br_if, LabelIdx}) ->
  do_encode_instr1(16#0C, LabelIdx);
do_encode({call, FuncIdx}) ->
  do_encode_instr1(16#10, FuncIdx);
do_encode({call_indirect, TypeIdx}) ->
  EncodedFront = do_encode_instr1(16#11, TypeIdx),
  <<EncodedFront/binary, 16#00>>;

%% Memory instructions
do_encode({i32_load, MemArg}) -> do_encode_instr1(16#28, MemArg);
do_encode({i64_load, MemArg}) -> do_encode_instr1(16#29, MemArg);
do_encode({f32_load, MemArg}) -> do_encode_instr1(16#2A, MemArg);
do_encode({f64_load, MemArg}) -> do_encode_instr1(16#2B, MemArg);
do_encode({i32_load8_s, MemArg}) -> do_encode_instr1(16#2C, MemArg);
do_encode({i32_load8_u, MemArg}) -> do_encode_instr1(16#2D, MemArg);
do_encode({i32_load16_s, MemArg}) -> do_encode_instr1(16#2E, MemArg);
do_encode({i32_load16_u, MemArg}) -> do_encode_instr1(16#2F, MemArg);
do_encode({i64_load8_s, MemArg}) -> do_encode_instr1(16#30, MemArg);
do_encode({i64_load8_u, MemArg}) -> do_encode_instr1(16#31, MemArg);
do_encode({i64_load16_s, MemArg}) -> do_encode_instr1(16#32, MemArg);
do_encode({i64_load16_u, MemArg}) -> do_encode_instr1(16#33, MemArg);
do_encode({i64_load32_s, MemArg}) -> do_encode_instr1(16#34, MemArg);
do_encode({i64_load32_u, MemArg}) -> do_encode_instr1(16#35, MemArg);
do_encode({i32_store, MemArg}) -> do_encode_instr1(16#36, MemArg);
do_encode({i64_store, MemArg}) -> do_encode_instr1(16#37, MemArg);
do_encode({f32_store, MemArg}) -> do_encode_instr1(16#38, MemArg);
do_encode({f64_store, MemArg}) -> do_encode_instr1(16#39, MemArg);
do_encode({i32_store8, MemArg}) -> do_encode_instr1(16#3A, MemArg);
do_encode({i32_store16, MemArg}) -> do_encode_instr1(16#3B, MemArg);
do_encode({i64_store8, MemArg}) -> do_encode_instr1(16#3C, MemArg);
do_encode({i64_store16, MemArg}) -> do_encode_instr1(16#3D, MemArg);
do_encode({i64_store32, MemArg}) -> do_encode_instr1(16#3E, MemArg);
do_encode({current_memory, MemArg}) -> do_encode_instr1(16#3F, MemArg);
do_encode({grow_memory, MemArg}) -> do_encode_instr1(16#40, MemArg);
do_encode({mem_arg, Align, Offset}) ->
  EncodedAlign = do_encode({u32, Align}),
  EncodedOffset = do_encode({u32, Offset}),
  <<EncodedAlign/binary, EncodedOffset/binary>>;

%% Variable instructions
do_encode(get_local) -> do_encode_instr0(16#20);
do_encode(set_local) -> do_encode_instr0(16#21);
do_encode(tee_local) -> do_encode_instr0(16#22);
do_encode(get_global) -> do_encode_instr0(16#23);
do_encode(set_global) -> do_encode_instr0(16#24);

%% Numeric instructions
do_encode(i32_eqz) -> do_encode_instr0(16#45);
do_encode(i32_eq) -> do_encode_instr0(16#46);
do_encode(i32_ne) -> do_encode_instr0(16#47);
do_encode(i32_lt_s) -> do_encode_instr0(16#48);
do_encode(i32_lt_u) -> do_encode_instr0(16#49);
do_encode(i32_gt_s) -> do_encode_instr0(16#4A);
do_encode(i32_gt_u) -> do_encode_instr0(16#4B);
do_encode(i32_le_s) -> do_encode_instr0(16#4C);
do_encode(i32_le_u) -> do_encode_instr0(16#4D);
do_encode(i32_ge_s) -> do_encode_instr0(16#4E);
do_encode(i32_ge_u) -> do_encode_instr0(16#4F);
do_encode(i64_eqz) -> do_encode_instr0(16#50);
do_encode(i64_eq) -> do_encode_instr0(16#51);
do_encode(i64_ne) -> do_encode_instr0(16#52);
do_encode(i64_lt_s) -> do_encode_instr0(16#53);
do_encode(i64_lt_u) -> do_encode_instr0(16#54);
do_encode(i64_gt_s) -> do_encode_instr0(16#55);
do_encode(i64_gt_u) -> do_encode_instr0(16#56);
do_encode(i64_le_s) -> do_encode_instr0(16#57);
do_encode(i64_le_u) -> do_encode_instr0(16#58);
do_encode(i64_ge_s) -> do_encode_instr0(16#59);
do_encode(i64_ge_u) -> do_encode_instr0(16#5A);
do_encode(f32_eq) -> do_encode_instr0(16#5B);
do_encode(f32_ne) -> do_encode_instr0(16#5C);
do_encode(f32_lt) -> do_encode_instr0(16#5D);
do_encode(f32_gt) -> do_encode_instr0(16#5E);
do_encode(f32_le) -> do_encode_instr0(16#5F);
do_encode(f32_ge) -> do_encode_instr0(16#60);
do_encode(f64_eq) -> do_encode_instr0(16#61);
do_encode(f64_ne) -> do_encode_instr0(16#62);
do_encode(f64_lt) -> do_encode_instr0(16#63);
do_encode(f64_gt) -> do_encode_instr0(16#64);
do_encode(f64_le) -> do_encode_instr0(16#65);
do_encode(f64_ge) -> do_encode_instr0(16#66);
do_encode(i32_clz) -> do_encode_instr0(16#67);
do_encode(i32_ctz) -> do_encode_instr0(16#68);
do_encode(i32_popcnt) -> do_encode_instr0(16#69);
do_encode(i32_add) -> do_encode_instr0(16#6A);
do_encode(i32_sub) -> do_encode_instr0(16#6B);
do_encode(i32_mul) -> do_encode_instr0(16#6C);
do_encode(i32_div_s) -> do_encode_instr0(16#6D);
do_encode(i32_div_u) -> do_encode_instr0(16#6E);
do_encode(i32_rem_s) -> do_encode_instr0(16#6F);
do_encode(i32_rem_u) -> do_encode_instr0(16#70);
do_encode(i32_and) -> do_encode_instr0(16#71);
do_encode(i32_or) -> do_encode_instr0(16#72);
do_encode(i32_xor) -> do_encode_instr0(16#73);
do_encode(i32_shl) -> do_encode_instr0(16#74);
do_encode(i32_shr_s) -> do_encode_instr0(16#75);
do_encode(i32_shr_u) -> do_encode_instr0(16#76);
do_encode(i32_rotl) -> do_encode_instr0(16#77);
do_encode(i32_rotr) -> do_encode_instr0(16#78);
do_encode(i64_clz) -> do_encode_instr0(16#79);
do_encode(i64_ctz) -> do_encode_instr0(16#7A);
do_encode(i64_popcnt) -> do_encode_instr0(16#7B);
do_encode(i64_add) -> do_encode_instr0(16#7C);
do_encode(i64_sub) -> do_encode_instr0(16#7D);
do_encode(i64_mul) -> do_encode_instr0(16#7E);
do_encode(i64_div_s) -> do_encode_instr0(16#7F);
do_encode(i64_div_u) -> do_encode_instr0(16#80);
do_encode(i64_rem_s) -> do_encode_instr0(16#81);
do_encode(i64_rem_u) -> do_encode_instr0(16#82);
do_encode(i64_and) -> do_encode_instr0(16#83);
do_encode(i64_or) -> do_encode_instr0(16#84);
do_encode(i64_xor) -> do_encode_instr0(16#85);
do_encode(i64_shl) -> do_encode_instr0(16#86);
do_encode(i64_shr_s) -> do_encode_instr0(16#87);
do_encode(i64_shr_u) -> do_encode_instr0(16#88);
do_encode(i64_rotl) -> do_encode_instr0(16#89);
do_encode(i64_rotr) -> do_encode_instr0(16#8A);
do_encode(f32_abs) -> do_encode_instr0(16#8B);
do_encode(f32_neg) -> do_encode_instr0(16#8C);
do_encode(f32_ceil) -> do_encode_instr0(16#8D);
do_encode(f32_floor) -> do_encode_instr0(16#8E);
do_encode(f32_trunc) -> do_encode_instr0(16#8F);
do_encode(f32_nearest) -> do_encode_instr0(16#90);
do_encode(f32_sqrt) -> do_encode_instr0(16#91);
do_encode(f32_add) -> do_encode_instr0(16#92);
do_encode(f32_sub) -> do_encode_instr0(16#93);
do_encode(f32_mul) -> do_encode_instr0(16#94);
do_encode(f32_div) -> do_encode_instr0(16#95);
do_encode(f32_min) -> do_encode_instr0(16#96);
do_encode(f32_max) -> do_encode_instr0(16#97);
do_encode(f32_copysign) -> do_encode_instr0(16#98);
do_encode(f64_abs) -> do_encode_instr0(16#99);
do_encode(f64_neg) -> do_encode_instr0(16#9A);
do_encode(f64_ceil) -> do_encode_instr0(16#9B);
do_encode(f64_floor) -> do_encode_instr0(16#9C);
do_encode(f64_trunc) -> do_encode_instr0(16#9D);
do_encode(f64_nearest) -> do_encode_instr0(16#9E);
do_encode(f64_sqrt) -> do_encode_instr0(16#9F);
do_encode(f64_add) -> do_encode_instr0(16#A0);
do_encode(f64_sub) -> do_encode_instr0(16#A1);
do_encode(f64_mul) -> do_encode_instr0(16#A2);
do_encode(f64_div) -> do_encode_instr0(16#A3);
do_encode(f64_min) -> do_encode_instr0(16#A4);
do_encode(f64_max) -> do_encode_instr0(16#A5);
do_encode(f64_copysign) -> do_encode_instr0(16#A6);
do_encode(i32_wrap_i64) -> do_encode_instr0(16#A7);
do_encode(i32_trunc_s_f32) -> do_encode_instr0(16#A8);
do_encode(i32_trunc_u_f32) -> do_encode_instr0(16#A9);
do_encode({i32_const, N}) -> do_encode_instr1(16#41, {i32, N});
do_encode({i64_const, N}) -> do_encode_instr1(16#42, {i64, N});
do_encode({f32_const, N}) -> do_encode_instr1(16#43, {f32, N});
do_encode({f64_const, N}) -> do_encode_instr1(16#44, {f64, N});

%% Expressions
do_encode({expr, Instrs}) ->
  EncodedInstrs = do_encode_sequence(Instrs),
  <<EncodedInstrs/binary>>;

%% Vector value
do_encode({vec, Items}) ->
  EncodedSize = do_encode({u32, length(Items)}),
  EncodedItems = do_encode_sequence(Items),
  <<EncodedSize/binary, EncodedItems/binary>>;

%% Name value
do_encode({name, Name}) -> <<Name/utf8>>;

%% Float value
do_encode({f32, Value}) -> <<Value:32/float>>;
do_encode({f64, Value}) -> <<Value:64/float>>;

%% Number values
do_encode({u32, Value}) -> eleb128:unsigned_encode(Value);
do_encode({u64, Value}) -> eleb128:unsigned_encode(Value);
do_encode({s32, Value}) -> eleb128:signed_encode(Value);
do_encode({s64, Value}) -> eleb128:signed_encode(Value);
do_encode({i32, Value}) -> eleb128:signed_encode(Value);
do_encode({i64, Value}) -> eleb128:signed_encode(Value).

%% Encodes any section
do_encode_section(Id, Contents) ->
  EncodedContents = do_encode(Contents),
  EncodedSize = do_encode({u32, byte_size(EncodedContents)}),
  <<Id, EncodedSize/binary, EncodedContents/binary>>.

%% Encodes any sequence of terms
do_encode_sequence(Terms) ->
  lists:foldl(fun(Term, Rest) ->
    EncodedTerm = do_encode(Term),
    <<Rest/binary, EncodedTerm/binary>>
  end, <<>>, Terms).

%% Generic instruction encodings
do_encode_instr0(Id) -> <<Id>>.
do_encode_instr1(Id, Term1) ->
  EncodedTerm1 = do_encode(Term1),
  <<Id, EncodedTerm1/binary>>.
do_encode_instr2(Id, Term1, Term2) ->
  EncodedTerm1 = do_encode(Term1),
  EncodedTerm2 = do_encode(Term2),
  <<Id, EncodedTerm1/binary, EncodedTerm2/binary>>.
