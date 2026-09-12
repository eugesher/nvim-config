-- NestJS snippets for TypeScript, loaded by LuaSnip's from_lua loader
-- (settings/completion/luasnip.lua). Placeholders with the same name are mirrored
-- (`repeat_duplicates`). Imports a snippet does not bring along come from
-- `<leader>cm` (add missing imports).

local ls = require("luasnip")
local s, i, c, t = ls.snippet, ls.insert_node, ls.choice_node, ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

local function nest(trig, desc, body, nodes)
  return s({ trig = trig, desc = desc }, fmt(body, nodes, { repeat_duplicates = true }))
end

return {
  nest(
    "nctrl",
    "NestJS controller: @Controller() with an injected service and a GET route",
    [[
import {{ Controller, Get }} from '@nestjs/common';
import {{ {Name}Service }} from './{file}.service';

@Controller('{route}')
export class {Name}Controller {{
  constructor(private readonly {inst}Service: {Name}Service) {{}}

  @Get()
  {method}() {{
    return this.{inst}Service.{method}();
  }}
}}]],
    {
      Name = i(1, "Users"),
      file = i(2, "users"),
      route = i(3, "users"),
      inst = i(4, "users"),
      method = i(5, "findAll"),
    }
  ),

  nest(
    "nsvc",
    "NestJS service: @Injectable() provider",
    [[
import {{ Injectable }} from '@nestjs/common';

@Injectable()
export class {Name}Service {{
  {body}
}}]],
    { Name = i(1, "Users"), body = i(0) }
  ),

  nest(
    "nmod",
    "NestJS module: imports / controllers / providers / exports",
    [[
import {{ Module }} from '@nestjs/common';

@Module({{
  imports: [{imports}],
  controllers: [{controllers}],
  providers: [{providers}],
  exports: [{exports}],
}})
export class {Name}Module {{}}]],
    {
      Name = i(1, "Users"),
      imports = i(2),
      controllers = i(3, "UsersController"),
      providers = i(4, "UsersService"),
      exports = i(5, "UsersService"),
    }
  ),

  nest(
    "ndto",
    "DTO class with class-validator decorators",
    [[
import {{ IsNotEmpty, IsString }} from 'class-validator';

export class {Name}Dto {{
  @IsString()
  @IsNotEmpty()
  readonly {field}: string;{more}
}}]],
    { Name = i(1, "CreateUser"), field = i(2, "name"), more = i(0) }
  ),

  nest(
    "nent",
    "TypeORM entity: @Entity(), @PrimaryGeneratedColumn(), @Column()",
    [[
import {{ Column, Entity, PrimaryGeneratedColumn }} from 'typeorm';

@Entity('{table}')
export class {Name} {{
  @PrimaryGeneratedColumn('{strategy}')
  id: {idType};

  @Column()
  {field}: string;{more}
}}]],
    {
      Name = i(1, "User"),
      table = i(2, "users"),
      strategy = c(3, { t("uuid"), t("increment") }),
      idType = i(4, "string"),
      field = i(5, "name"),
      more = i(0),
    }
  ),

  nest(
    "nrepo",
    "Constructor parameter: TypeORM repository via @InjectRepository()",
    [[
@InjectRepository({Entity})
private readonly {inst}Repository: Repository<{Entity}>,]],
    { Entity = i(1, "User"), inst = i(2, "user") }
  ),

  nest(
    "nmsg",
    "RabbitMQ handler: @MessagePattern() (request/response) or @EventPattern() (event)",
    [[
@{decorator}('{pattern}')
async {handler}(@Payload() data: {Type}{context}) {{
  {body}
}}]],
    {
      decorator = c(1, { t("MessagePattern"), t("EventPattern") }),
      pattern = i(2, "users.created"),
      handler = i(3, "handleUserCreated"),
      Type = i(4, "unknown"),
      context = c(5, { t(""), t(", @Ctx() context: RmqContext") }),
      body = i(0),
    }
  ),

  nest(
    "ndesc",
    "Jest: describe block",
    [[
describe('{subject}', () => {{
  {body}
}});]],
    { subject = i(1, "UsersService"), body = i(0) }
  ),

  nest(
    "nit",
    "Jest: it block (async)",
    [[
it('should {behavior}', async () => {{
  {body}
}});]],
    { behavior = i(1, "work"), body = i(0) }
  ),

  nest(
    "ntest",
    "NestJS unit spec: Test.createTestingModule with the provider under test",
    [[
import {{ Test, TestingModule }} from '@nestjs/testing';
import {{ {Name} }} from './{file}';

describe('{Name}', () => {{
  let {inst}: {Name};

  beforeEach(async () => {{
    const module: TestingModule = await Test.createTestingModule({{
      providers: [{Name}],
    }}).compile();

    {inst} = module.get<{Name}>({Name});
  }});

  it('should be defined', () => {{
    expect({inst}).toBeDefined();
  }});{body}
}});]],
    {
      Name = i(1, "UsersService"),
      file = i(2, "users.service"),
      inst = i(3, "service"),
      body = i(0),
    }
  ),
}
