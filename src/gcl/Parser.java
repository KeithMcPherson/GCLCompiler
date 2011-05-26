package gcl;

public class Parser {
// GCL Version 2011
	public static final int _EOF = 0;
	public static final int _identifier = 1;
	public static final int _numeral = 2;
	public static final int _stringConstant = 3;
	public static final int maxT = 57;
	public static final int _option1 = 58;
	public static final int _option3 = 59;
	public static final int _option5 = 60;
	public static final int _option6 = 61;
	public static final int _option7 = 62;
	public static final int _option9 = 63;
	public static final int _option10 = 64;

	static final boolean T = true;
	static final boolean x = false;
	static final int minErrDist = 2;

	public Token t;    // last recognized token
	public Token la;   // lookahead token
	int errDist = minErrDist;
	
	private Scanner scanner;
	private Errors errors;

	static final boolean DIRECT = CodegenConstants.DIRECT;
		static final boolean INDIRECT = CodegenConstants.INDIRECT;
		IntegerType integerType = SemanticActions.INTEGER_TYPE;
		BooleanType booleanType = SemanticActions.BOOLEAN_TYPE;
		TypeDescriptor noType = SemanticActions.NO_TYPE;

/*==========================================================*/


	public Parser(Scanner scanner, SemanticActions actions, SemanticActions.GCLErrorStream err) {
		this.scanner = scanner;
		this.semantic = actions;
		errors = err;
		this.err = err;
	}
	
	private SemanticActions semantic;
	private SemanticActions.GCLErrorStream err;
	
	public Scanner scanner(){
		return scanner;
	}
	
	public Token currentToken(){return t;}

	void SynErr (int n) {
		if (errDist >= minErrDist) errors.SynErr(la.line, la.col, n);
		errDist = 0;
	}

	public void SemErr (String msg) {
		if (errDist >= minErrDist) errors.Error(t.line, t.col, msg);
		errDist = 0;
	}
	
	void Get () {
		for (;;) {
			t = la;
			la = scanner.Scan();
			if (la.kind <= maxT) { ++errDist; break; }

			if (la.kind == 58) {
				CompilerOptions.listCode = la.val.charAt(2) == '+'; 
			}
			if (la.kind == 59) {
				CompilerOptions.optimize = la.val.charAt(2) == '+'; 
			}
			if (la.kind == 60) {
				SymbolTable.dumpAll(); 
			}
			if (la.kind == 61) {
			}
			if (la.kind == 62) {
				CompilerOptions.showMessages = la.val.charAt(2) == '+'; 
			}
			if (la.kind == 63) {
				CompilerOptions.printAllocatedRegisters(); 
			}
			if (la.kind == 64) {
			}
			la = t;
		}
	}
	
	void Expect (int n) {
		if (la.kind==n) Get(); else { SynErr(n); }
	}
	
	boolean StartOf (int s) {
		return set[s][la.kind];
	}
	
	void ExpectWeak (int n, int follow) {
		if (la.kind == n) Get();
		else {
			SynErr(n);
			while (!StartOf(follow)) Get();
		}
	}
	
	boolean WeakSeparator (int n, int syFol, int repFol) {
		boolean[] s = new boolean[maxT+1];
		if (la.kind == n) { Get(); return true; }
		else if (StartOf(repFol)) return false;
		else {
			for (int i=0; i <= maxT; i++) {
				s[i] = set[syFol][i] || set[repFol][i] || set[0][i];
			}
			SynErr(n);
			while (!s[la.kind]) Get();
			return StartOf(syFol);
		}
	}
	
	void gcl() {
		semantic.startCode();  SymbolTable scope = SymbolTable.currentScope(); 
		while (!(la.kind == 0 || la.kind == 4)) {SynErr(58); Get();}
		module(scope);
		while (la.kind == 4) {
			scope = scope.openScope(true); 
			while (!(la.kind == 0 || la.kind == 4)) {SynErr(59); Get();}
			module(scope);
		}
		semantic.finishCode(); 
	}

	void module(SymbolTable scope) {
		Identifier id; 
		Expect(4);
		Expect(1);
		id = new Identifier(currentToken().spelling()); semantic.declareModule(scope, id); 
		definitionPart(scope);
		if (la.kind == 5) {
			Get();
			SymbolTable privateScope = scope.openScope(false); semantic.declarePrivateScope(scope); 
			block(privateScope);
		}
		Expect(6);
	}

	void definitionPart(SymbolTable scope) {
		while (StartOf(1)) {
			while (!(StartOf(2))) {SynErr(60); Get();}
			definition(scope);
			ExpectWeak(9, 3);
		}
	}

	void block(SymbolTable scope) {
		definitionPart(scope);
		while (!(la.kind == 0 || la.kind == 7)) {SynErr(61); Get();}
		Expect(7);
		semantic.doLink(); 
		statementPart(scope);
		Expect(8);
	}

	void statementPart(SymbolTable scope) {
		while (!(StartOf(4))) {SynErr(62); Get();}
		statement(scope);
		ExpectWeak(9, 5);
		while (StartOf(6)) {
			while (!(StartOf(4))) {SynErr(63); Get();}
			statement(scope);
			ExpectWeak(9, 5);
		}
	}

	void definition(SymbolTable scope) {
		if (StartOf(7)) {
			variableDefinition(scope, ParameterKind.NOT_PARAM);
		} else if (la.kind == 11) {
			constantDefinition(scope);
		} else if (la.kind == 15) {
			typeDefinition(scope);
		} else if (la.kind == 19) {
			procedureDefinition(scope);
		} else SynErr(64);
	}

	void statement(SymbolTable scope) {
		switch (la.kind) {
		case 30: {
			emptyStatement();
			break;
		}
		case 31: {
			readStatement(scope);
			break;
		}
		case 32: {
			writeStatement(scope);
			break;
		}
		case 1: {
			assignOrCallStatement(scope);
			break;
		}
		case 34: {
			ifStatement(scope);
			break;
		}
		case 36: {
			doStatement(scope);
			break;
		}
		case 38: {
			forStatement(scope);
			break;
		}
		case 26: {
			returnStatement();
			break;
		}
		default: SynErr(65); break;
		}
	}

	void variableDefinition(SymbolTable scope, ParameterKind kindOfParam) {
		TypeDescriptor type; Identifier id; 
		type = type(scope);
		Expect(1);
		id = new Identifier(currentToken().spelling());
		semantic.declareVariable(scope, type, id, kindOfParam);
		
		while (la.kind == 10) {
			Get();
			Expect(1);
			id = new Identifier(currentToken().spelling());
			semantic.declareVariable(scope, type, id, kindOfParam);
			
		}
	}

	void constantDefinition(SymbolTable scope) {
		Expression expr; Identifier id; 
		Expect(11);
		Expect(1);
		id = new Identifier(currentToken().spelling()); 
		Expect(12);
		expr = constant(scope);
		semantic.declareConstant(scope, id, expr); 
	}

	void typeDefinition(SymbolTable scope) {
		Identifier id; TypeDescriptor type;
		Expect(15);
		type = type(scope);
		Expect(1);
		id = new Identifier(currentToken().spelling()); 
		semantic.declareType(scope, id, type); 
	}

	void procedureDefinition(SymbolTable scope) {
		Identifier tupleID; Identifier procID; Procedure proc; 
		Expect(19);
		Expect(1);
		tupleID = new Identifier(currentToken().spelling()); 
		Expect(25);
		Expect(1);
		procID = new Identifier(currentToken().spelling()); 
		proc = semantic.defineProcedure(procID, scope.lookupIdentifier(tupleID).semanticRecord()); 
		scope = proc.getScope();
		
		block(scope);
		semantic.endDefineProcedure(proc); 
	}

	TypeDescriptor  type(SymbolTable scope) {
		TypeDescriptor  result;
		result = noType; 
		if (la.kind == 1 || la.kind == 13 || la.kind == 14) {
			result = typeSymbol(scope);
			if (la.kind == 27 || la.kind == 28) {
				if (la.kind == 27) {
					result = arrayType(result, scope);
				} else {
					result = rangeType(result, scope);
				}
			}
		} else if (la.kind == 16) {
			result = tupleType(scope);
		} else SynErr(66);
		return result;
	}

	ConstantExpression  constant(SymbolTable scope) {
		ConstantExpression  result;
		Expression expr; 
		expr = expression(scope);
		result = expr.expectConstant(expr, err); 
		return result;
	}

	Expression  expression(SymbolTable scope) {
		Expression  left;
		Expression right; 
		left = andExpr(scope);
		while (la.kind == 42) {
			Get();
			right = andExpr(scope);
			left = semantic.booleanExpression(left, BooleanOperator.OR, right); 
		}
		return left;
	}

	TypeDescriptor  typeSymbol(SymbolTable scope) {
		TypeDescriptor  result;
		Identifier id; result = null; SemanticItem typeDef; 
		if (la.kind == 13) {
			Get();
			result = integerType; 
		} else if (la.kind == 14) {
			Get();
			result = booleanType; 
		} else if (la.kind == 1) {
			typeDef = qualifiedIdentifier(scope);
			id = new Identifier(currentToken().spelling());
			typeDef = semantic.semanticValue(scope, id); 
			result = typeDef.expectType(err);
		} else SynErr(67);
		return result;
	}

	ArrayType  arrayType(TypeDescriptor baseType, SymbolTable scope) {
		ArrayType  result;
		
		SemanticItem subscriptType; ArrayCarrier carrier = new ArrayCarrier();
		Expect(27);
		Expect(17);
		subscriptType = typeSymbol(scope);
		carrier.push(subscriptType.expectType(err), err); 
		Expect(18);
		while (la.kind == 17) {
			Get();
			subscriptType = typeSymbol(scope);
			carrier.push(subscriptType.expectType(err), err); 
			Expect(18);
		}
		result = semantic.buildArray(baseType, carrier, err); 
		return result;
	}

	TypeDescriptor  rangeType(TypeDescriptor baseType, SymbolTable scope) {
		TypeDescriptor  result;
		ConstantExpression lowBound; ConstantExpression highBound; 
		Expect(28);
		Expect(17);
		lowBound = constant(scope);
		Expect(29);
		highBound = constant(scope);
		Expect(18);
		result = semantic.buildRange(baseType, lowBound, highBound); 
		return result;
	}

	TupleType  tupleType(SymbolTable scope) {
		TupleType  result;
		result = null; TypeList carrier = new TypeList(); 
		Expect(16);
		Expect(17);
		if (la.kind == 19) {
			carrier = justProcs(carrier, scope);
		} else if (la.kind == 1 || la.kind == 13 || la.kind == 14) {
			carrier = fieldsAndProcs(carrier, scope);
		} else SynErr(68);
		Expect(18);
		result = new TupleType(carrier); 
		return result;
	}

	SemanticItem  qualifiedIdentifier(SymbolTable scope) {
		SemanticItem  result;
		Expect(1);
		Identifier id = new Identifier(currentToken().spelling()); result = semantic.semanticValue(scope, id); 
		if (la.kind == 6) {
			Get();
			Expect(1);
			Identifier modulesID = new Identifier(currentToken().spelling()); 
			result = semantic.semanticValue(scope, id, modulesID); 
		}
		return result;
	}

	TypeList  justProcs(TypeList currentCarrier, SymbolTable scope) {
		TypeList  carrier;
		Procedure proc; carrier = currentCarrier; 
		proc = procedureDeclaration(scope);
		carrier.enterProc(proc); 
		while (la.kind == 10) {
			Get();
			proc = procedureDeclaration(scope);
			carrier.enterProc(proc); 
		}
		return carrier;
	}

	TypeList  fieldsAndProcs(TypeList currentCarrier, SymbolTable scope) {
		TypeList  carrier;
		TypeDescriptor type; Identifier id; carrier = currentCarrier; 
		type = typeSymbol(scope);
		Expect(1);
		id = new Identifier(currentToken().spelling()); carrier.enter(type, id);
		carrier = moreFieldsAndProcs(carrier, scope);
		return carrier;
	}

	Procedure  procedureDeclaration(SymbolTable scope) {
		Procedure  proc;
		Identifier id;
		Expect(19);
		Expect(1);
		id = new Identifier(currentToken().spelling());  
		proc = semantic.declareProcedure(scope, id); scope = proc.getScope(); 
		paramPart(scope);
		semantic.endDeclareProcedure(); 
		return proc;
	}

	TypeList  moreFieldsAndProcs(TypeList currentCarrier, SymbolTable scope) {
		TypeList  carrier;
		TypeDescriptor type; Identifier id; carrier = currentCarrier; 
		if (la.kind == 10 || la.kind == 19) {
			if (la.kind == 10) {
				Get();
				if (la.kind == 1 || la.kind == 13 || la.kind == 14) {
					type = typeSymbol(scope);
					Expect(1);
					id = new Identifier(currentToken().spelling()); carrier.enter(type, id);
				}
				carrier = moreFieldsAndProcs(carrier, scope);
			} else {
				if (la.kind == 19) {
					carrier = justProcs(carrier, scope);
				}
			}
		}
		return carrier;
	}

	void paramPart(SymbolTable scope) {
		Expect(20);
		if (la.kind == 22 || la.kind == 23) {
			paramDefinition(scope);
			while (la.kind == 9) {
				Get();
				paramDefinition(scope);
			}
		}
		Expect(21);
	}

	void paramDefinition(SymbolTable scope) {
		if (la.kind == 22) {
			Get();
			variableDefinition(scope, ParameterKind.VALUE_PARAM);
		} else if (la.kind == 23) {
			Get();
			variableDefinition(scope, ParameterKind.REFERENCE_PARAM);
		} else SynErr(69);
	}

	void callStatement(Expression tupleExpression, SymbolTable scope) {
		Expression exp; Identifier procID; 
		Expect(24);
		Expect(1);
		procID = new Identifier(currentToken().spelling()); 
		argumentList(scope);
		semantic.callProcedure(tupleExpression, procID); 
	}

	void argumentList(SymbolTable scope) {
		Expect(20);
		if (StartOf(8)) {
			Expression exp; ExpressionList tupleFields = new ExpressionList(); 
			exp = expression(scope);
			while (la.kind == 10) {
				Get();
				exp = expression(scope);
			}
		}
		Expect(21);
	}

	void assignOrCallStatement(SymbolTable scope) {
		Expression exp; 
		exp = variableAccessEtc(scope);
		if (la.kind == 10 || la.kind == 33) {
			assignStatement(scope, exp);
		} else if (la.kind == 24) {
			callStatement(exp, scope);
		} else SynErr(70);
	}

	Expression  variableAccessEtc(SymbolTable scope) {
		Expression  result;
		SemanticItem workValue; 
		workValue = qualifiedIdentifier(scope);
		result = workValue.expectExpression(err); 
		result = subsAndCompons(result, scope);
		return result;
	}

	void assignStatement(SymbolTable scope, Expression left) {
		AssignRecord expressions = new AssignRecord(); Expression exp = left; 
		expressions.left(exp); 
		while (la.kind == 10) {
			Get();
			exp = variableAccessEtc(scope);
			expressions.left(exp); 
		}
		Expect(33);
		exp = expression(scope);
		expressions.right(exp); 
		while (la.kind == 10) {
			Get();
			exp = expression(scope);
			expressions.right(exp); 
		}
		semantic.parallelAssign(expressions); 
	}

	void returnStatement() {
		Expect(26);
		semantic.doReturn(); 
	}

	void emptyStatement() {
		Expect(30);
	}

	void readStatement(SymbolTable scope) {
		Expression exp; 
		Expect(31);
		exp = variableAccessEtc(scope);
		semantic.readVariable(exp); 
		while (la.kind == 10) {
			Get();
			exp = variableAccessEtc(scope);
			semantic.readVariable(exp); 
		}
	}

	void writeStatement(SymbolTable scope) {
		Expect(32);
		writeItem(scope);
		while (la.kind == 10) {
			Get();
			writeItem(scope);
		}
		semantic.genEol(); 
	}

	void ifStatement(SymbolTable scope) {
		GCRecord ifRecord; 
		Expect(34);
		ifRecord = semantic.startIf(); 
		guardedCommandList(scope, ifRecord );
		Expect(35);
		semantic.endIf(ifRecord); 
	}

	void doStatement(SymbolTable scope) {
		GCRecord doRecord; 
		Expect(36);
		doRecord = semantic.startDo(); 
		guardedCommandList(scope, doRecord );
		Expect(37);
	}

	void forStatement(SymbolTable scope) {
		Expression exp; int startLabel;
		Expect(38);
		exp = variableAccessEtc(scope);
		Expect(39);
		startLabel =  semantic.startFor(exp); 
		statementPart(scope);
		Expect(40);
		semantic.endFor(exp, startLabel); 
	}

	void writeItem(SymbolTable scope) {
		Expression exp; 
		if (StartOf(8)) {
			exp = expression(scope);
			semantic.writeExpression(exp); 
		} else if (la.kind == 3) {
			Get();
			semantic.writeStringConstant(new StringConstant(currentToken().spelling())); 
		} else SynErr(71);
	}

	void guardedCommandList(SymbolTable scope, GCRecord ifRecord) {
		guardedCommand(scope, ifRecord);
		while (la.kind == 41) {
			Get();
			guardedCommand(scope, ifRecord);
		}
	}

	void guardedCommand(SymbolTable scope, GCRecord  ifRecord ) {
		Expression expr; 
		expr = expression(scope);
		semantic.ifTest(expr, ifRecord); 
		Expect(39);
		statementPart(scope);
		semantic.elseIf(ifRecord); 
	}

	Expression  andExpr(SymbolTable scope) {
		Expression  left;
		Expression right; 
		left = relationalExpr(scope);
		while (la.kind == 43) {
			Get();
			right = relationalExpr(scope);
			left = semantic.booleanExpression(left, BooleanOperator.AND, right); 
		}
		return left;
	}

	Expression  relationalExpr(SymbolTable scope) {
		Expression  left;
		Expression right; RelationalOperator op; 
		left = simpleExpr(scope);
		if (StartOf(9)) {
			op = relationalOperator();
			right = simpleExpr(scope);
			left = semantic.compareExpression(left, op, right); 
		}
		return left;
	}

	Expression  simpleExpr(SymbolTable scope) {
		Expression  left;
		Expression right; AddOperator op; left = null; 
		if (StartOf(10)) {
			if (la.kind == 44) {
				Get();
			}
			left = term(scope);
		} else if (la.kind == 45) {
			Get();
			left = term(scope);
			left = semantic.negateExpression(left); 
		} else SynErr(72);
		while (la.kind == 44 || la.kind == 45) {
			op = addOperator();
			right = term(scope);
			left = semantic.addExpression(left, op, right); 
		}
		return left;
	}

	RelationalOperator  relationalOperator() {
		RelationalOperator  op;
		op = null; 
		switch (la.kind) {
		case 12: {
			Get();
			op = RelationalOperator.EQUAL; 
			break;
		}
		case 49: {
			Get();
			op = RelationalOperator.NOT_EQUAL; 
			break;
		}
		case 50: {
			Get();
			op = RelationalOperator.LESS_THAN; 
			break;
		}
		case 51: {
			Get();
			op = RelationalOperator.LESS_THAN_EQUAL; 
			break;
		}
		case 52: {
			Get();
			op = RelationalOperator.GREATER_THAN; 
			break;
		}
		case 53: {
			Get();
			op = RelationalOperator.GREATER_THAN_EQUAL; 
			break;
		}
		default: SynErr(73); break;
		}
		return op;
	}

	Expression  term(SymbolTable scope) {
		Expression  left;
		Expression right; MultiplyOperator op; 
		left = factor(scope);
		while (la.kind == 54 || la.kind == 55 || la.kind == 56) {
			op = multiplyOperator();
			right = factor(scope);
			left = semantic.multiplyExpression(left, op, right); 
		}
		return left;
	}

	AddOperator  addOperator() {
		AddOperator  op;
		op = null; 
		if (la.kind == 44) {
			Get();
			op = AddOperator.PLUS; 
		} else if (la.kind == 45) {
			Get();
			op = AddOperator.MINUS; 
		} else SynErr(74);
		return op;
	}

	Expression  factor(SymbolTable scope) {
		Expression  result;
		result = null; 
		switch (la.kind) {
		case 1: {
			result = variableAccessEtc(scope);
			semantic.terminateArray(result); 
			break;
		}
		case 2: {
			Get();
			result = new ConstantExpression (integerType, Integer.parseInt(currentToken().spelling()));
			
			break;
		}
		case 20: {
			Get();
			result = expression(scope);
			Expect(21);
			break;
		}
		case 17: {
			Expression exp;
			ExpressionList tupleFields = new ExpressionList();
			
			Get();
			exp = expression(scope);
			tupleFields.enter(exp); 
			while (la.kind == 10) {
				Get();
				exp = expression(scope);
				tupleFields.enter(exp); 
			}
			Expect(18);
			result = semantic.buildTuple(tupleFields); 
			break;
		}
		case 47: case 48: {
			result = booleanConstant();
			break;
		}
		case 46: {
			Get();
			result = factor(scope);
			result = semantic.booleanNegate(result); 
			break;
		}
		default: SynErr(75); break;
		}
		return result;
	}

	MultiplyOperator  multiplyOperator() {
		MultiplyOperator  op;
		op = null; 
		if (la.kind == 54) {
			Get();
			op = MultiplyOperator.TIMES; 
		} else if (la.kind == 55) {
			Get();
			op = MultiplyOperator.DIVIDE; 
		} else if (la.kind == 56) {
			Get();
			op = MultiplyOperator.MODULUS; 
		} else SynErr(76);
		return op;
	}

	ConstantExpression  booleanConstant() {
		ConstantExpression  value;
		value = null; 
		if (la.kind == 47) {
			Get();
			value = new ConstantExpression (booleanType, 1); 
		} else if (la.kind == 48) {
			Get();
			value = new ConstantExpression (booleanType, 0); 
		} else SynErr(77);
		return value;
	}

	Expression  subsAndCompons(Expression value, SymbolTable scope) {
		Expression  result;
		Expression subscriptValue; result = value;
		while (la.kind == 17 || la.kind == 25) {
			if (la.kind == 17) {
				Get();
				subscriptValue = expression(scope);
				Expect(18);
				result = semantic.subscriptAction(result, subscriptValue); 
			} else {
				Get();
				Expect(1);
				Identifier id = new Identifier(currentToken().spelling()); result = semantic.extractField(result, id); 
			}
		}
		return result;
	}



	public void Parse() {
		la = new Token();
		la.val = "";		
		Get();
		gcl();

		Expect(0);
	}

	private boolean[][] set = {
		{T,T,x,x, T,x,x,T, x,x,x,T, x,T,T,T, T,x,x,T, x,x,x,x, x,x,T,x, x,x,T,T, T,x,T,x, T,x,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x},
		{x,T,x,x, x,x,x,x, x,x,x,T, x,T,T,T, T,x,x,T, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x},
		{T,T,x,x, x,x,x,x, x,x,x,T, x,T,T,T, T,x,x,T, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x},
		{T,T,x,x, T,T,T,T, x,x,x,T, x,T,T,T, T,x,x,T, x,x,x,x, x,x,T,x, x,x,T,T, T,x,T,x, T,x,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x},
		{T,T,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,T,x, x,x,T,T, T,x,T,x, T,x,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x},
		{T,T,x,x, T,x,x,T, T,x,x,T, x,T,T,T, T,x,x,T, x,x,x,x, x,x,T,x, x,x,T,T, T,x,T,T, T,T,T,x, T,T,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x},
		{x,T,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,T,x, x,x,T,T, T,x,T,x, T,x,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x},
		{x,T,x,x, x,x,x,x, x,x,x,x, x,T,T,x, T,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x},
		{x,T,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,T,x,x, T,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, T,T,T,T, T,x,x,x, x,x,x,x, x,x,x},
		{x,x,x,x, x,x,x,x, x,x,x,x, T,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,T,T,T, T,T,x,x, x,x,x},
		{x,T,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,T,x,x, T,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, T,x,T,T, T,x,x,x, x,x,x,x, x,x,x}

	};
} // end Parser


class Errors {
	public int count = 0;
	public String errMsgFormat = "-- line {0} col {1}: {2}";
	Scanner scanner;
	
	public Errors(Scanner scanner)
	{
		this.scanner = scanner;
	}

	private void printMsg(int line, int column, String msg) {
		StringBuffer b = new StringBuffer(errMsgFormat);
		int pos = b.indexOf("{0}");
		if (pos >= 0) { b.delete(pos, pos+3); b.insert(pos, line); }
		pos = b.indexOf("{1}");
		if (pos >= 0) { b.delete(pos, pos+3); b.insert(pos, column); }
		pos = b.indexOf("{2}");
		if (pos >= 0) b.replace(pos, pos+3, msg);
		scanner.outFile().println(b.toString());
	}
	
	public void SynErr (int line, int col, int n) {
			String s;
			switch (n) {
			case 0: s = "EOF expected"; break;
			case 1: s = "identifier expected"; break;
			case 2: s = "numeral expected"; break;
			case 3: s = "stringConstant expected"; break;
			case 4: s = "\"module\" expected"; break;
			case 5: s = "\"private\" expected"; break;
			case 6: s = "\".\" expected"; break;
			case 7: s = "\"begin\" expected"; break;
			case 8: s = "\"end\" expected"; break;
			case 9: s = "\";\" expected"; break;
			case 10: s = "\",\" expected"; break;
			case 11: s = "\"constant\" expected"; break;
			case 12: s = "\"=\" expected"; break;
			case 13: s = "\"integer\" expected"; break;
			case 14: s = "\"Boolean\" expected"; break;
			case 15: s = "\"typedefinition\" expected"; break;
			case 16: s = "\"tuple\" expected"; break;
			case 17: s = "\"[\" expected"; break;
			case 18: s = "\"]\" expected"; break;
			case 19: s = "\"procedure\" expected"; break;
			case 20: s = "\"(\" expected"; break;
			case 21: s = "\")\" expected"; break;
			case 22: s = "\"value\" expected"; break;
			case 23: s = "\"reference\" expected"; break;
			case 24: s = "\"!\" expected"; break;
			case 25: s = "\"@\" expected"; break;
			case 26: s = "\"return\" expected"; break;
			case 27: s = "\"array\" expected"; break;
			case 28: s = "\"range\" expected"; break;
			case 29: s = "\"..\" expected"; break;
			case 30: s = "\"skip\" expected"; break;
			case 31: s = "\"read\" expected"; break;
			case 32: s = "\"write\" expected"; break;
			case 33: s = "\":=\" expected"; break;
			case 34: s = "\"if\" expected"; break;
			case 35: s = "\"fi\" expected"; break;
			case 36: s = "\"do\" expected"; break;
			case 37: s = "\"od\" expected"; break;
			case 38: s = "\"forall\" expected"; break;
			case 39: s = "\"->\" expected"; break;
			case 40: s = "\"llarof\" expected"; break;
			case 41: s = "\"[]\" expected"; break;
			case 42: s = "\"|\" expected"; break;
			case 43: s = "\"&\" expected"; break;
			case 44: s = "\"+\" expected"; break;
			case 45: s = "\"-\" expected"; break;
			case 46: s = "\"~\" expected"; break;
			case 47: s = "\"true\" expected"; break;
			case 48: s = "\"false\" expected"; break;
			case 49: s = "\"#\" expected"; break;
			case 50: s = "\"<\" expected"; break;
			case 51: s = "\"<=\" expected"; break;
			case 52: s = "\">\" expected"; break;
			case 53: s = "\">=\" expected"; break;
			case 54: s = "\"*\" expected"; break;
			case 55: s = "\"/\" expected"; break;
			case 56: s = "\"\\\\\" expected"; break;
			case 57: s = "??? expected"; break;
			case 58: s = "this symbol not expected in gcl"; break;
			case 59: s = "this symbol not expected in gcl"; break;
			case 60: s = "this symbol not expected in definitionPart"; break;
			case 61: s = "this symbol not expected in block"; break;
			case 62: s = "this symbol not expected in statementPart"; break;
			case 63: s = "this symbol not expected in statementPart"; break;
			case 64: s = "invalid definition"; break;
			case 65: s = "invalid statement"; break;
			case 66: s = "invalid type"; break;
			case 67: s = "invalid typeSymbol"; break;
			case 68: s = "invalid tupleType"; break;
			case 69: s = "invalid paramDefinition"; break;
			case 70: s = "invalid assignOrCallStatement"; break;
			case 71: s = "invalid writeItem"; break;
			case 72: s = "invalid simpleExpr"; break;
			case 73: s = "invalid relationalOperator"; break;
			case 74: s = "invalid addOperator"; break;
			case 75: s = "invalid factor"; break;
			case 76: s = "invalid multiplyOperator"; break;
			case 77: s = "invalid booleanConstant"; break;
				default: s = "error " + n; break;
			}
			printMsg(line, col, s);
			count++;
			CompilerOptions.genHalt();
	}

	public void SemErr (int line, int col, int n) {
		printMsg(line, col, "error " + n);
		count++;
	}

	void semanticError(int n){
		SemErr(scanner.t.line, scanner.t.col, n); 
	}

	void semanticError(int n, int line, int col){
		SemErr(line, col, n);
	}

	void semanticError(int n, int line, int col, String message){
		scanner.outFile().print(message + ": ");
		semanticError(n, line, col);
	}

	void semanticError(int n, String message){
		scanner.outFile().print(message + ": ");
		semanticError(n);
	}

	public void Error (int line, int col, String s) {	
		printMsg(line, col, s);
		count++;
	}

	public void Exception (String s) {
		scanner.outFile().println(s); 
		System.exit(1);
	}
} // Errors

class FatalError extends RuntimeException {
	public static final long serialVersionUID = 1L;
	public FatalError(String s) { super(s); }
}


