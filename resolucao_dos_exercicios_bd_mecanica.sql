# Início das resoluções
#Questao01

delimiter $$
create procedure novaVenda (dataDaVenda date, formaDeRecebimento varchar (50), quantidadeDeParcelas int, idFuncionario int, idCliente int)
begin

if((select id_cli from cliente where id_cli = idCliente) is not null) then
	if ((select id_func from funcionario where id_func = idFuncionario) is not null) then
		if(formaDeRecebimento = 'parcelado') then
			if (quantidadeDeParcelas > 1 and quantidadeDeParcelas <= 6) then
				insert into venda (data_vend, valor_total_vend, desconto_vend, forma_recebimento_vend, parcelas_vend, id_func_fk, id_cli_fk) values (dataDaVenda, 0.0, 0.0, formaDeRecebimento, quantidadeDeParcelas, idFuncionario, idCliente);
				select 'A venda parcelada foi registrada no sistema.' as Confirmacao;
			else
				select 'A venda não foi realizada.' as Erro;
			end if;
		else
			if(formaDeRecebimento = 'a vista') then
				if (quantidadeDeParcelas = 1) then
					insert into venda (data_vend, valor_total_vend, desconto_vend, forma_recebimento_vend, parcelas_vend, id_func_fk, id_cli_fk) values (dataDaVenda, 0.0, 0.0, formaDeRecebimento, quantidadeDeParcelas, idFuncionario, idCliente);
					select 'A venda a vista foi registrada no sistema' as Confirmacao;
				else
					select 'A venda não foi realizada.' as Erro;
				end if;
			else
				select 'A venda não foi realizada.' as Erro;
			end if;
		end if;
	else
		select 'O funcionário indicado não está cadastrado no sistema.' as Erro;
	end if;
else
	select 'O cliente indicado não está cadastrado no sistema.' as Erro;
end if;

end;
$$ delimiter ;

call novaVenda('2021-10-24', 'a vista', 1, 2, 7);
call novaVenda('2021-10-24', 'parcelado', 6, 2, 8);

#Questao02

delimiter $$
create trigger adicionarNovoValorTotalDaVenda after insert on itens_venda for each row
begin

declare valorDoProduto float;
select valor_prod into valorDoProduto from produto where id_prod = new.id_prod_fk;
update venda set valor_total_vend = valor_total_vend + (new.quant_itv * valorDoProduto) where id_vend = new.id_vend_fk;

end;
$$ delimiter ;

delimiter $$
create procedure itensParaVenda (quantidadeDeProdutos int, idProduto int, idVenda int)
begin

if ((select quant_prod from produto where id_prod = idProduto) >= quantidadeDeProdutos) then
	insert into itens_venda (quant_itv, id_prod_fk, id_vend_fk) values (quantidadeDeProdutos, idProduto, idVenda);
    update produto set quant_prod = quant_prod - quantidadeDeProdutos where id_prod = idProduto;
    select 'Os produtos foram inseridos.' as Confirmacao;
else
	select 'Os produtos não foram inseridos.' as Erro;
end if;

end;
$$ delimiter ;

call itensParaVenda(2, 1, 1);
call itensParaVenda(2, 9, 1);
call itensParaVenda(2, 14, 1);

call itensParaVenda(5, 5, 2);
call itensParaVenda(3, 6, 2);
call itensParaVenda(10, 7, 2);

#Questao03

delimiter $$
create trigger removerItensDaVenda after delete on itens_venda for each row
begin

declare valorDoItem float;
select valor_prod into valorDoItem from produto where id_prod = old.id_prod_fk;
update venda set valor_total_vend = valor_total_vend - (old.quant_itv * valorDoItem) where id_vend = old.id_vend_fk;
update produto set quant_prod = quant_prod + old.quant_itv where id_prod = old.id_prod_fk;

end;
$$ delimiter ;

delimiter $$
create procedure deletarItensDaVenda (idItem int)
begin

delete from itens_venda where id_itv = idItem;

end;
$$ delimiter ;

call deletarItensDaVenda(6);

#Questao04

delimiter $$
create procedure venderProdutos (idVenda int, desconto double)
begin

declare valorVenda float;
declare dataVenda date;
declare parcelas int;
declare valorDaParcela float;
declare i int;
set i = 1;

if (desconto > 0) and (desconto <= 10) then
	update venda set desconto_vend = desconto where id_vend = idVenda;
	update venda set valor_total_vend = (valor_total_vend - (valor_total_vend * (desconto / 100))) where id_vend = idVenda;
else
	select 'A venda não terá desconto.';
end if;

select valor_total_vend into valorVenda from venda where id_vend = idVenda;
select data_vend into dataVenda from venda where id_vend = idVenda;
select parcelas_vend into parcelas from venda where id_vend = idVenda;

if ((select forma_recebimento_vend from venda where id_vend = idVenda) = 'a vista') then
	insert into recebimentos (data_vencimento_rec, valor_rec, parcela_rec, status_rec, forma_recebimento_rec, data_recebimento_rec, id_func_fk, id_vend_fk) values (dataVenda, valorVenda, parcelas, 'Em aberto', null, null, null, idVenda);
    select 'A parcela da venda a vista foi registrada no sistema.' as Confirmacao;
else
	if ((select forma_recebimento_vend from venda where id_vend = idVenda) = 'parcelado') then
        set valorDaParcela = valorVenda / parcelas;
		while (i <= parcelas) do
			insert into recebimentos (data_vencimento_rec, valor_rec, parcela_rec, status_rec, forma_recebimento_rec, data_recebimento_rec, id_func_fk, id_vend_fk) values ((select date_add(dataVenda, INTERVAL i month)), valorDaParcela, i, 'Em aberto', null, null, null, idVenda);
            select concat('A parcela ', i, ' da venda foi registrada no sistema.') as Confirmacao;
            set i = i + 1;
		end while;
	else
		select 'As parcelas da venda não foram registradas no sistema.' as Erro;
	end if;
end if;

end;
$$ delimiter ;

call venderProdutos(1, 10);
call venderProdutos(2, 6);

#Questao05

delimiter $$
create trigger receber after update on recebimentos for each row
begin

declare valorRecebido float;
select valor_rec into valorRecebido from recebimentos where id_rec = new.id_rec;
update caixa set valor_creditos_cai = valor_creditos_cai + valorRecebido where id_cai = new.id_cai_fk;

end;
$$ delimiter ;

#Questao06

delimiter $$
create procedure receberVenda (idRecebimento int, formaDeRecebimento varchar (100), dataRecebimento date, idCaixa int, idFuncionario int)
begin

declare dataVencimento date;
select data_vencimento_rec into dataVencimento from recebimentos where id_rec = idRecebimento;

if((select status_cai from caixa where id_cai = idCaixa) = 'Aberto') then
	if((select id_dep from departamento where nome_dep = 'Financeiro') = (select id_dep_fk from funcionario where id_func = idFuncionario)) then
		update recebimentos set status_rec = 'Pago' where id_rec = idRecebimento;
        update recebimentos set forma_recebimento_rec = formaDeRecebimento where id_rec = idRecebimento;
		update recebimentos set data_recebimento_rec = dataRecebimento where id_rec = idRecebimento;
        update recebimentos set id_func_fk = idFuncionario where id_rec = idRecebimento;
        update recebimentos set id_cai_fk = idCaixa where id_rec = idRecebimento;
        if (date(dataRecebimento) > date(dataVencimento)) then
			update recebimentos set valor_rec = (valor_rec + (valor_rec * (5 / 100))) where id_rec = idRecebimento;
            select 'A parcela foi paga atrasada, por isso houve multa de 5% no valor' as Alerta;
		end if;
        select 'O pagamento da parcela foi recebido.' as Mensagem;
	else
		select 'O funcionario indicado não pode realizar recebimentos.' as Erro;
	end if;
else
	select 'O caixa indicado não aberto.' as Erro;
end if;
end;
$$ delimiter ;


call receberVenda(2, 'dinheiro', '2021-11-25', 2, 6);
call receberVenda(3, 'dinheiro', '2021-12-23', 2, 6);

#Questao07

delimiter $$
create procedure novaCompra (dataCompra date, formaDePagamento varchar (100), idFuncionario int, idFornecedor int)
begin

if((select id_forn from fornecedor where id_forn = idFornecedor) is not null) then
	if ((select id_func from funcionario where id_func = idFuncionario) is not null) then
		if ((select id_dep from departamento where nome_dep = 'Administração') = (select id_dep_fk from funcionario where id_func = idFuncionario)) then
			if(formaDePagamento = 'a vista') or (formaDePagamento = 'parcelado 2 vezes') then
				insert into compra_produto (data_comp, valor_total_comp, forma_pagamento_comp, id_func_fk, id_forn_fk) values (dataCompra, 0, formaDePagamento, idFuncionario, idFornecedor);
				select 'A compra foi registrada no sistema.' as Confirmacao;
			else
				select 'A compra não foi registrada no sistema.' as Erro;
			end if;
		else
			select 'O funcionário indicado pertence a um departamento que não pode registrar compras.' as Erro;
		end if;
	else
		select 'O funcionário indicado não está cadastrado no sistema.' as Erro;
	end if;
else
	select 'O fornecedor indicado não está cadastrado no sistema.' as Erro;
end if;

end;
$$ delimiter ;

call novaCompra('2021-11-24', 'a vista', 1, 7);
call novaCompra('2021-11-24', 'parcelado 2 vezes', 1, 6);

#Questao08

delimiter $$
create trigger adicionarNovoValorTotalCompra after insert on itens_compra for each row
begin

update compra_produto set valor_total_comp = valor_total_comp + (new.quant_itc * new.valor_itc) where id_comp = new.id_comp_fk;
update produto set quant_prod = quant_prod + new.quant_itc where id_prod = new.id_prod_fk;

end;
$$ delimiter ;

delimiter $$
create procedure itensParaCompra (quantidadeDeItens int, idProduto int, idCompra int)
begin

declare valorItem float;
select valor_prod into valorItem from produto where id_prod = idProduto;
insert into itens_compra (quant_itc, valor_itc, id_prod_fk, id_comp_fk) values (quantidadeDeItens, valorItem, idProduto, idCompra);
select 'Os produtos foram inseridos.' as Confirmacao;

end;
$$ delimiter ;

call itensParaCompra(2, 1, 1);
call itensParaCompra(2, 5, 1);
call itensParaCompra(2, 6, 1);
call itensParaCompra(2, 8, 1);
call itensParaCompra(2, 9, 1);

call itensParaCompra(2, 1, 2);
call itensParaCompra(2, 5, 2);
call itensParaCompra(2, 6, 2);
call itensParaCompra(2, 8, 2);
call itensParaCompra(2, 9, 2);

#Questao09

delimiter $$
create trigger removerItensDaCompra after delete on itens_compra for each row
begin

update compra_produto set valor_total_comp = valor_total_comp - (old.quant_itc * old.valor_itc) where id_comp = old.id_comp_fk;
update produto set quant_prod = quant_prod - old.quant_itc where id_prod = old.id_prod_fk;

end;
$$ delimiter ;

delimiter $$
create procedure deleteItensDaCompra (idItens int)
begin

delete from itens_compra where id_itc = idItens;

end;
$$ delimiter ;

call deleteItensDaCompra (8);

#Questao10

delimiter $$
create procedure ComprarProdutos (idCompra int)
begin

declare i int;
declare valorCompra float;
declare dataCompra date;
declare valorDaParcela float;
set i = 1;

select valor_total_comp into valorCompra from compra_produto where id_comp = idCompra;
select data_comp into dataCompra from compra_produto where id_comp = idCompra;

if ((select forma_pagamento_comp from compra_produto where id_comp = idCompra) = 'a vista') then
    insert into pagamentos (data_vencimento_pag, valor_pag, parcela_pag, status_pag, forma_pagamento_pag, data_pagamento_pag, id_func_fk, id_cai_fk, id_desp_fk, id_comp_fk) values (dataCompra, valorCompra, 'a vista', 'Em aberto', null, null, null, null, null, idCompra);
    select 'A compra a vista foi registrada no sistema.' as Confirmacao;
else
	if ((select forma_pagamento_comp from compra_produto where id_comp = idCompra) = 'parcelado 2 vezes') then
        set valorDaParcela = valorCompra / 2;
		while (i <= 2) do
			insert into pagamentos (data_vencimento_pag, valor_pag, parcela_pag, status_pag, forma_pagamento_pag, data_pagamento_pag, id_func_fk, id_cai_fk, id_desp_fk, id_comp_fk) values ((select date_add(dataCompra, INTERVAL i month)), valorDaParcela, 'parcelado 2 vezes', 'Em aberto', null, null, null, null, null, idCompra);
            select concat('A parcela ', i, ' da compra foi registrada no sistema.') as Confirmacao;
            set i = i + 1;
		end while;
	else
		select 'As parcelas não foram registradas no sistema.' as Erro;
	end if;
end if;

end;
$$ delimiter ;

call ComprarProdutos(1);
call ComprarProdutos(2);

#Questao11

delimiter $$
create trigger registrarPagamento after update on pagamentos for each row
begin

declare valorPagamento float;
select valor_pag into valorPagamento from pagamentos where id_pag = new.id_pag;
update caixa set valor_debitos_cai = valor_debitos_cai + valorPagamento where id_cai = new.id_cai_fk;

end;
$$ delimiter ;

#Questao12

delimiter $$
create procedure pagar (idPagamento int, formaDePagamento varchar (100), dataDePagamento date, idFuncionario int, idCaixa int, idDespesa int)
begin

declare dataDeVencimento date;
select data_vencimento_pag into dataDeVencimento from pagamentos where id_pag = idPagamento;

if((select status_cai from caixa where id_cai = idCaixa) = 'Aberto') then
	if((select id_dep from departamento where nome_dep = 'Financeiro') = (select id_dep_fk from funcionario where id_func = idFuncionario)) then
		update pagamentos set status_pag = 'Pago' where id_pag = idPagamento;
        update pagamentos set forma_pagamento_pag = formaDePagamento where id_pag = idPagamento;
		update pagamentos set data_pagamento_pag = dataDePagamento where id_pag = idPagamento;
        update pagamentos set id_func_fk = idFuncionario where id_pag = idPagamento;
        update pagamentos set id_cai_fk = idCaixa where id_pag = idPagamento;
        update pagamentos set id_desp_fk = idDespesa where id_pag = idPagamento;
        if (date(dataDePagamento) > date(dataDeVencimento)) then
			update pagamentos set valor_pag = (valor_pag + (valor_pag * (5 / 100))) where id_pag = idPagamento;
            select 'A parcela foi paga atrasada, por isso houve multa de 5% no valor' as Alerta;
		end if;
        select 'O pagamento foi recebido.' as Confirmacao;
	else
		select 'O pagamento não pode ser realizado. O caixa indicado não está aberto.' as Erro;
	end if;
else
	select 'O caixa indicado não está aberto.' as Erro;
end if;
end;
$$ delimiter ;

call pagar (2, 'cartão', '2021-11-20', 6, 2, null);
call pagar (3, 'cartão', '2021-12-25', 6, 2, null);

select * from produto;
select * from venda;
select * from caixa;
select * from itens_venda;
select * from recebimentos;
select * from compra_produto;
select * from itens_compra;
select * from pagamentos;