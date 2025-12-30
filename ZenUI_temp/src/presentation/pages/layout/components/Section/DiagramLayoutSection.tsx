import {
  DiagramLayout,
  DiagramNode,
  DiagramWrapper,
} from "../../../../components/package/layouts/diagram";
import {
  CodeBlock,
  CodeBlockHeader,
  CodeBlockBody,
} from "../../../../components/package/components/codeblock";
import { FileCode, Activity } from "lucide-react";

const DiagramLayoutSection = () => {
  const usageCode = `import { DiagramLayout, DiagramNode, DiagramWrapper } from "@khanhromvn/zenui";

function MyDiagram() {
  return (
    <DiagramLayout 
      className="h-[1000px] border border-border-default rounded-xl"
      autoLayout={true}
      layoutOptions={{
        nodeSpacing: 200,
        iterations: 300,
        edgeWeight: 0.2,
        repulsionStrength: 10000,
      }}
    >
      <DiagramWrapper
        id="wrapper-handler"
        title="handlers/auth.handler.go"
        fit={true}
        className="border border-dashed border-purple-300 rounded-xl p-4"
      >
        <DiagramNode id="node-handler">
          {/* Handler code */}
        </DiagramNode>
      </DiagramWrapper>
    </DiagramLayout>
  );
}`;

  // Handler Code
  const handlerCode = `func HandleRegister(w http.ResponseWriter, r *http.Request) {
    var req dto.RegisterRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        response.Error(w, http.StatusBadRequest, "Invalid request body")
        return
    }

    // Validate request
    if err := validator.ValidateRegisterRequest(req); err != nil {
        response.Error(w, http.StatusBadRequest, err.Error())
        return
    }

    // Call service
    user, err := service.RegisterUser(req)
    if err != nil {
        response.Error(w, http.StatusInternalServerError, err.Error())
        return
    }

    response.Success(w, http.StatusCreated, user)
}`;

  // DTO Types
  const dtoCode = `type RegisterRequest struct {
    Email     string \`json:"email" validate:"required,email"\`
    Username  string \`json:"username" validate:"required,min=3,max=50"\`
    Password  string \`json:"password" validate:"required,min=8"\`
    FullName  string \`json:"full_name" validate:"required"\`
}

type RegisterResponse struct {
    ID        string    \`json:"id"\`
    Email     string    \`json:"email"\`
    Username  string    \`json:"username"\`
    FullName  string    \`json:"full_name"\`
    CreatedAt time.Time \`json:"created_at"\`
}`;

  // Validator Code
  const validatorCode = `func ValidateRegisterRequest(req dto.RegisterRequest) error {
    // Email validation
    if err := ValidateEmail(req.Email); err != nil {
        return fmt.Errorf("invalid email: %w", err)
    }

    // Username validation
    if err := ValidateUsername(req.Username); err != nil {
        return fmt.Errorf("invalid username: %w", err)
    }

    // Password strength validation
    if err := ValidatePasswordStrength(req.Password); err != nil {
        return fmt.Errorf("weak password: %w", err)
    }

    return nil
}`;

  const validateEmailCode = `func ValidateEmail(email string) error {
    emailRegex := regexp.MustCompile(\`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$\`)
    
    if !emailRegex.MatchString(email) {
        return errors.New("invalid email format")
    }
    
    return nil
}`;

  const validateUsernameCode = `func ValidateUsername(username string) error {
    if len(username) < 3 {
        return errors.New("username too short")
    }
    
    if len(username) > 50 {
        return errors.New("username too long")
    }
    
    usernameRegex := regexp.MustCompile(\`^[a-zA-Z0-9_]+$\`)
    if !usernameRegex.MatchString(username) {
        return errors.New("username contains invalid characters")
    }
    
    return nil
}`;

  const validatePasswordCode = `func ValidatePasswordStrength(password string) error {
    if len(password) < 8 {
        return errors.New("password must be at least 8 characters")
    }
    
    hasUpper := regexp.MustCompile(\`[A-Z]\`).MatchString(password)
    hasLower := regexp.MustCompile(\`[a-z]\`).MatchString(password)
    hasNumber := regexp.MustCompile(\`[0-9]\`).MatchString(password)
    hasSpecial := regexp.MustCompile(\`[!@#$%^&*]\`).MatchString(password)
    
    if !hasUpper || !hasLower || !hasNumber || !hasSpecial {
        return errors.New("password must contain uppercase, lowercase, number, and special character")
    }
    
    return nil
}`;

  // Service Code
  const serviceCode = `func RegisterUser(req dto.RegisterRequest) (*dto.RegisterResponse, error) {
    // Check if user exists
    exists, err := repository.CheckUserExists(req.Email, req.Username)
    if err != nil {
        return nil, fmt.Errorf("failed to check user: %w", err)
    }
    
    if exists {
        return nil, errors.New("user already exists")
    }

    // Hash password
    hashedPassword, err := bcrypt.HashPassword(req.Password)
    if err != nil {
        return nil, fmt.Errorf("failed to hash password: %w", err)
    }

    // Create user entity
    user := entity.User{
        ID:        uuid.New().String(),
        Email:     req.Email,
        Username:  req.Username,
        Password:  hashedPassword,
        FullName:  req.FullName,
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
    }

    // Save to database
    if err := repository.CreateUser(&user); err != nil {
        return nil, fmt.Errorf("failed to create user: %w", err)
    }

    // Send welcome email
    go email.SendWelcomeEmail(user.Email, user.FullName)

    return &dto.RegisterResponse{
        ID:        user.ID,
        Email:     user.Email,
        Username:  user.Username,
        FullName:  user.FullName,
        CreatedAt: user.CreatedAt,
    }, nil
}`;

  // Repository Code
  const repoCheckCode = `func CheckUserExists(email, username string) (bool, error) {
    var count int
    query := \`
        SELECT COUNT(*) FROM users 
        WHERE email = $1 OR username = $2
    \`
    
    err := db.QueryRow(query, email, username).Scan(&count)
    if err != nil {
        return false, fmt.Errorf("query error: %w", err)
    }
    
    return count > 0, nil
}`;

  const repoCreateCode = `func CreateUser(user *entity.User) error {
    query := \`
        INSERT INTO users (id, email, username, password, full_name, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
    \`
    
    _, err := db.Exec(
        query,
        user.ID,
        user.Email,
        user.Username,
        user.Password,
        user.FullName,
        user.CreatedAt,
        user.UpdatedAt,
    )
    
    if err != nil {
        return fmt.Errorf("insert error: %w", err)
    }
    
    return nil
}`;

  // Entity Code
  const entityCode = `type User struct {
    ID        string    \`db:"id" json:"id"\`
    Email     string    \`db:"email" json:"email"\`
    Username  string    \`db:"username" json:"username"\`
    Password  string    \`db:"password" json:"-"\`
    FullName  string    \`db:"full_name" json:"full_name"\`
    CreatedAt time.Time \`db:"created_at" json:"created_at"\`
    UpdatedAt time.Time \`db:"updated_at" json:"updated_at"\`
    DeletedAt *time.Time \`db:"deleted_at" json:"deleted_at,omitempty"\`
}

func (u *User) TableName() string {
    return "users"
}`;

  // Bcrypt Utility
  const bcryptCode = `func HashPassword(password string) (string, error) {
    hashedBytes, err := bcrypt.GenerateFromPassword(
        []byte(password),
        bcrypt.DefaultCost,
    )
    
    if err != nil {
        return "", fmt.Errorf("hash generation failed: %w", err)
    }
    
    return string(hashedBytes), nil
}

func ComparePassword(hashedPassword, password string) error {
    return bcrypt.CompareHashAndPassword(
        []byte(hashedPassword),
        []byte(password),
    )
}`;

  // Email Service
  const emailCode = `func SendWelcomeEmail(to, fullName string) error {
    subject := "Welcome to Our Platform!"
    body := fmt.Sprintf(\`
        Hello %s,

        Thank you for registering with us!
        We're excited to have you on board.

        Best regards,
        The Team
    \`, fullName)

    msg := mail.NewMessage()
    msg.SetHeader("From", config.SMTPFrom)
    msg.SetHeader("To", to)
    msg.SetHeader("Subject", subject)
    msg.SetBody("text/plain", body)

    dialer := mail.NewDialer(
        config.SMTPHost,
        config.SMTPPort,
        config.SMTPUser,
        config.SMTPPassword,
    )

    if err := dialer.DialAndSend(msg); err != nil {
        log.Printf("Failed to send welcome email: %v", err)
        return err
    }

    return nil
}`;

  // Response Utility
  const responseCode = `func Success(w http.ResponseWriter, statusCode int, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(statusCode)
    
    response := map[string]interface{}{
        "success": true,
        "data":    data,
    }
    
    json.NewEncoder(w).Encode(response)
}

func Error(w http.ResponseWriter, statusCode int, message string) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(statusCode)
    
    response := map[string]interface{}{
        "success": false,
        "error":   message,
    }
    
    json.NewEncoder(w).Encode(response)
}`;

  const edges: any[] = [
    // Handler -> DTO
    {
      id: "e1",
      from: "node-handler",
      to: "node-dto",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "uses",
      color: "#3b82f6",
      width: 2,
    },

    // Handler -> Validator
    {
      id: "e2",
      from: "node-handler",
      to: "node-validator",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "validates",
      color: "#8b5cf6",
      width: 2,
    },

    // Handler -> Service
    {
      id: "e3",
      from: "node-handler",
      to: "node-service",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "calls",
      color: "#10b981",
      width: 2,
    },

    // Handler -> Response
    {
      id: "e4",
      from: "node-handler",
      to: "node-response",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "returns",
      color: "#f59e0b",
      width: 2,
    },

    // Validator -> ValidateEmail
    {
      id: "e5",
      from: "node-validator",
      to: "node-validate-email",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "checks",
      color: "#8b5cf6",
      width: 2,
      style: "dashed",
    },

    // Validator -> ValidateUsername
    {
      id: "e6",
      from: "node-validator",
      to: "node-validate-username",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "checks",
      color: "#8b5cf6",
      width: 2,
      style: "dashed",
    },

    // Validator -> ValidatePassword
    {
      id: "e7",
      from: "node-validator",
      to: "node-validate-password",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "checks",
      color: "#8b5cf6",
      width: 2,
      style: "dashed",
    },

    // Service -> Repository Check
    {
      id: "e8",
      from: "node-service",
      to: "node-repo-check",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "checks",
      color: "#10b981",
      width: 2,
    },

    // Service -> Bcrypt
    {
      id: "e9",
      from: "node-service",
      to: "node-bcrypt",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "hashes",
      color: "#10b981",
      width: 2,
    },

    // Service -> Entity
    {
      id: "e10",
      from: "node-service",
      to: "node-entity",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "creates",
      color: "#10b981",
      width: 2,
    },

    // Service -> Repository Create
    {
      id: "e11",
      from: "node-service",
      to: "node-repo-create",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "saves",
      color: "#10b981",
      width: 2,
    },

    // Service -> Email
    {
      id: "e12",
      from: "node-service",
      to: "node-email",
      fromDot: "auto",
      toDot: "auto",
      type: "bezier",
      label: "sends",
      color: "#10b981",
      width: 2,
      style: "dashed",
    },
  ];

  return (
    <section id="diagram-layout" className="mb-12">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <Activity className="text-blue-500" size={28} />
          <h2 className="text-3xl font-bold text-text-primary">
            Diagram Layout
          </h2>
        </div>
      </div>

      <p className="text-lg text-text-secondary mb-6 leading-relaxed">
        A specialized layout for node-based diagrams and flowcharts. This
        example demonstrates a complete backend registration flow with handlers,
        validators, services, repositories, and utilities.
      </p>

      {/* Live Demo */}
      <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
        <div className="h-[900px] relative rounded-xl border border-border-default overflow-hidden transition-all duration-500">
          <DiagramLayout
            className="h-full w-full"
            edges={edges}
            autoLayout={true}
            layoutOptions={{
              nodeSpacing: 200,
              iterations: 300,
              edgeWeight: 0.2,
              repulsionStrength: 10000,
            }}
          >
            {/* Handler Layer */}
            <DiagramWrapper
              id="wrapper-handler"
              title={
                <span className="text-xs font-semibold text-purple-600">
                  handlers/auth.handler.go
                </span>
              }
              fit={true}
              minWidth={300}
              minHeight={200}
              maxWidth={1200}
              maxHeight={1200}
              className="border border-dashed border-purple-300 rounded-xl p-4"
            >
              <DiagramNode
                id="node-handler"
                filename="handlers/auth.handler.go"
                fit={false}
                minWidth={450}
                minHeight={280}
                maxWidth={750}
                maxHeight={750}
                className="absolute"
              >
                <CodeBlock
                  code={handlerCode}
                  language="go"
                  filename="handlers/auth.handler.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>
            </DiagramWrapper>

            {/* DTO Layer */}
            <DiagramWrapper
              id="wrapper-dto"
              title={
                <span className="text-xs font-semibold text-blue-600">
                  dto/auth.dto.go
                </span>
              }
              fit={true}
              minWidth={300}
              minHeight={200}
              maxWidth={1200}
              maxHeight={1200}
              className="border border-dashed border-blue-300 rounded-xl p-4"
            >
              <DiagramNode
                id="node-dto"
                filename="dto/auth.dto.go"
                fit={false}
                minWidth={420}
                minHeight={240}
                maxWidth={720}
                maxHeight={720}
                className="absolute"
              >
                <CodeBlock
                  code={dtoCode}
                  language="go"
                  filename="dto/auth.dto.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>
            </DiagramWrapper>

            {/* Validator Layer */}
            <DiagramWrapper
              id="wrapper-validator"
              title={
                <span className="text-xs font-semibold text-violet-600">
                  validators/auth.validator.go
                </span>
              }
              fit={true}
              minWidth={300}
              minHeight={200}
              maxWidth={1400}
              maxHeight={1400}
              className="border border-dashed border-violet-300 rounded-xl p-4"
            >
              <DiagramNode
                id="node-validator"
                filename="validators/auth.validator.go"
                fit={false}
                minWidth={420}
                minHeight={220}
                maxWidth={720}
                maxHeight={720}
                className="absolute"
              >
                <CodeBlock
                  code={validatorCode}
                  language="go"
                  filename="validators/auth.validator.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>

              <DiagramNode
                id="node-validate-email"
                filename="validators/email.validator.go"
                fit={false}
                minWidth={380}
                minHeight={180}
                maxWidth={680}
                maxHeight={680}
                className="absolute"
              >
                <CodeBlock
                  code={validateEmailCode}
                  language="go"
                  filename="validators/email.validator.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>

              <DiagramNode
                id="node-validate-username"
                filename="validators/username.validator.go"
                fit={false}
                minWidth={400}
                minHeight={200}
                maxWidth={700}
                maxHeight={700}
                className="absolute"
              >
                <CodeBlock
                  code={validateUsernameCode}
                  language="go"
                  filename="validators/username.validator.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>

              <DiagramNode
                id="node-validate-password"
                filename="validators/password.validator.go"
                fit={false}
                minWidth={420}
                minHeight={240}
                maxWidth={720}
                maxHeight={720}
                className="absolute"
              >
                <CodeBlock
                  code={validatePasswordCode}
                  language="go"
                  filename="validators/password.validator.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>
            </DiagramWrapper>

            {/* Service Layer */}
            <DiagramWrapper
              id="wrapper-service"
              title={
                <span className="text-xs font-semibold text-emerald-600">
                  services/auth.service.go
                </span>
              }
              fit={true}
              minWidth={300}
              minHeight={200}
              maxWidth={1200}
              maxHeight={1200}
              className="border border-dashed border-emerald-300 rounded-xl p-4"
            >
              <DiagramNode
                id="node-service"
                filename="services/auth.service.go"
                fit={false}
                minWidth={480}
                minHeight={360}
                maxWidth={780}
                maxHeight={780}
                className="absolute"
              >
                <CodeBlock
                  code={serviceCode}
                  language="go"
                  filename="services/auth.service.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>
            </DiagramWrapper>

            {/* Repository Layer */}
            <DiagramWrapper
              id="wrapper-repository"
              title={
                <span className="text-xs font-semibold text-teal-600">
                  repositories/user.repository.go
                </span>
              }
              fit={true}
              minWidth={300}
              minHeight={200}
              maxWidth={1200}
              maxHeight={1200}
              className="border border-dashed border-teal-300 rounded-xl p-4"
            >
              <DiagramNode
                id="node-repo-check"
                filename="repositories/user.repository.go"
                fit={false}
                minWidth={420}
                minHeight={220}
                maxWidth={720}
                maxHeight={720}
                className="absolute"
              >
                <CodeBlock
                  code={repoCheckCode}
                  language="go"
                  filename="repositories/check_user.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>

              <DiagramNode
                id="node-repo-create"
                filename="repositories/user.repository.go"
                fit={false}
                minWidth={420}
                minHeight={240}
                maxWidth={720}
                maxHeight={720}
                className="absolute"
              >
                <CodeBlock
                  code={repoCreateCode}
                  language="go"
                  filename="repositories/create_user.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>
            </DiagramWrapper>

            {/* Entity Layer */}
            <DiagramWrapper
              id="wrapper-entity"
              title={
                <span className="text-xs font-semibold text-cyan-600">
                  entities/user.entity.go
                </span>
              }
              fit={true}
              minWidth={300}
              minHeight={200}
              maxWidth={1200}
              maxHeight={1200}
              className="border border-dashed border-cyan-300 rounded-xl  p-4"
            >
              <DiagramNode
                id="node-entity"
                filename="entities/user.entity.go"
                fit={false}
                minWidth={420}
                minHeight={220}
                maxWidth={720}
                maxHeight={720}
                className="absolute"
              >
                <CodeBlock
                  code={entityCode}
                  language="go"
                  filename="entities/user.entity.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>
            </DiagramWrapper>

            {/* Utilities Layer */}
            <DiagramWrapper
              id="wrapper-utils"
              title={
                <span className="text-xs font-semibold text-amber-600">
                  utils/
                </span>
              }
              fit={true}
              minWidth={300}
              minHeight={200}
              maxWidth={1400}
              maxHeight={1400}
              className="border border-dashed border-amber-300 rounded-xl  p-4"
            >
              <DiagramNode
                id="node-bcrypt"
                filename="utils/bcrypt.util.go"
                fit={false}
                minWidth={400}
                minHeight={220}
                maxWidth={700}
                maxHeight={700}
                className="absolute"
              >
                <CodeBlock
                  code={bcryptCode}
                  language="go"
                  filename="utils/bcrypt.util.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>

              <DiagramNode
                id="node-email"
                filename="utils/email.util.go"
                fit={false}
                minWidth={420}
                minHeight={280}
                maxWidth={720}
                maxHeight={720}
                className="absolute"
              >
                <CodeBlock
                  code={emailCode}
                  language="go"
                  filename="utils/email.util.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>

              <DiagramNode
                id="node-response"
                filename="utils/response.util.go"
                fit={false}
                minWidth={400}
                minHeight={240}
                maxWidth={700}
                maxHeight={700}
                className="absolute"
              >
                <CodeBlock
                  code={responseCode}
                  language="go"
                  filename="utils/response.util.go"
                  theme="vs-dark"
                  showLineNumbers={true}
                  className="h-full"
                >
                  <CodeBlockHeader />
                  <CodeBlockBody />
                </CodeBlock>
              </DiagramNode>
            </DiagramWrapper>
          </DiagramLayout>
        </div>
      </div>

      {/* Code Example */}
      <CodeBlock
        code={usageCode}
        language="typescript"
        theme="vs-dark"
        readOnly={true}
        headerMode="path"
        headerIcon={<FileCode size={16} />}
        filePath="src/components/DiagramExample.tsx"
        showLineNumbers={true}
        showGutter={true}
      />
    </section>
  );
};

export default DiagramLayoutSection;
